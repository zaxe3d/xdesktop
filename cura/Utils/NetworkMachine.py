from PyQt5.QtCore import QUrl, QCoreApplication, QTimer, QObject, pyqtSignal, QThread
from PyQt5 import QtCore, QtWebSockets, QtNetwork

#import ssl
import json
import os
import io
import ftplib
import traceback
import sys
import uuid
import time
from . import tool

from UM.Logger import Logger


class NetworkMachineEventArgs():

    message = None

    machine = None

    def __init__(self, machine, message):
        self.message = message
        self.machine = machine

class NetworkMachineUploadEventArgs():

    progress = None

    machine = None

    def __init__(self, machine, progress):
        self.progress = progress
        self.machine = machine

class NetworkMachine(QThread, QObject):

    ip = None

    id = None

    ftpPort = 9494

    name = None

    timeout = 20000 # timeout and close after xMilliSeconds

    machineEvent = pyqtSignal(NetworkMachineEventArgs)
    machineUploadEvent = pyqtSignal(NetworkMachineUploadEventArgs)

    def __init__(self, ip, port, name, parent = None):
        QObject.__init__(self)
        self.ip = ip
        self.port = port
        self.name = name
        self.id = uuid.uuid4().hex
        self.currentLen = 0
        self.networkId = None
        self.fileName = None
        self.currentSize = 0
        self.totalSize = 0
        self.nozzle = 0.4
        self.filamentColor = "unknown"
        self.printingFile = ""
        self.estimatedTime = ""
        self.material = ""
        self.deviceModel = "x1"
        self.hasPin = False
        self.hasNFCSpool = False
        self.hasSnapshot = False
        self.isLite = False
        self.nonTLS = False
        # anonymous ftp address (only for to serve the snapshot for now)
        self.snapshot = "ftp://" + self.ip + ":9494/snapshot.png"
        self.elapsedTime = 0
        self.filamentRemaining = 0
        self.fwVersion = [999, 0, 0]
        self.startTime = None
        self.__states = {}

        # class specific
        self.timer = None
        self.uploader = None

    def start(self):

        # create socket
        self.socket =  QtWebSockets.QWebSocket("", QtWebSockets.QWebSocketProtocol.Version13, None)
        # assign events
        self.socket.connected.connect(self.onConnected)
        self.socket.disconnected.connect(self.onDisconnected)
        self.socket.error.connect(self.onError)
        self.socket.textMessageReceived.connect(self.onMessage)

        Logger.log("d", "trying to connect: %s" % self.ip)
        # open connection
        self.socket.open(QUrl("ws://%s:%d" % (self.ip, self.port)))

    # Connection related
    def onConnected(self):
        if self.timer is not None:
            self.timer.stop()
        Logger.log("d", "connected: %s" % self.ip)

    def onDisconnected(self):
        if self.uploader is not None:
            self.uploader.stop()
        self.close()

    def onMessage(self, message):
        if self.timer is not None:
            self.timer.stop()
        self.startTimeout()

        #Logger.log("d", "onMessage: %s" % message)

        message = json.loads(message)

        if message['event'] == "hello":
            try:
                self.material = message['material'].lower()
            except:
                self.material = "abs"
            try:
                self.nozzle = message['nozzle']
            except:
                self.nozzle = 0.4
            try:
                self.fwVersion = [int(num) for num in message["version"].split(".")]
            except:
                traceback.print_exc()
                self.fwVersion = [999, 0, 0]
            try:
                self.deviceModel = message['device_model'].lower()
            except:
                self.deviceModel = "x1"

            # only z-series have snapshot available
            self.hasSnapshot = self.deviceModel[0] == "z"
            # lite series has short filename
            self.isLite = self.deviceModel.find("lite") >= 0 or self.deviceModel == "x3"
            # Z3 and Z2 series has no TLS (also lite series)
            self.nonTLS = self.deviceModel in ["z2", "z3"] or self.isLite

            try:
                self.printingFile = message["filename"]
                self.elapsedTime = 0 if "elapsed_time" not in message else float(message["elapsed_time"])
                self.startTime = time.time() - self.elapsedTime
                self.estimatedTime = message["estimated_time"]
                if not self.isLite:
                    self.hasPin = message["has_pin"].lower() == "true"
                    self.hasNFCSpool = message["has_nfc_spool"].lower() == "true" if "has_nfc_spool" in message else False
                    self.filamentRemaining = float(message["filament_remaining"]) if self.hasNFCSpool else 0
                    self.filamentColor = message["filament_color"] if self.hasNFCSpool else "unknown"
            except:
                self.printingFile = ""
                self.elapsedTime = 0
                self.estimatedTime = ""
                self.hasPin = False
                self.hasNFCSpool = False
                self.filamentRemaining = 0
                self.filamentColor = "unknown"

        if message['event'] in ["hello", "states_update"]:
            old_states = self.__states

            # backward compatiblity
            updating = False
            calibrating = False
            bedOccupied = False
            usbPresent = False
            if "is_calibrating" in message:
                calibrating = message["is_calibrating"].lower() == "true"
                bedOccupied = message["is_bed_occupied"].lower() == "true"

            if "is_updating" in message:
                updating = message["is_updating"].lower() == "true"

            if "is_usb_present" in message:
                usbPresent = message["is_usb_present"].lower() == "true"

            self.__states = {
                "updating": updating,
                "usb_present": usbPresent,
                "bed_occupied": bedOccupied,
                "calibrating": calibrating,
                "preheat": message["is_preheat"].lower() == "true",
                "printing": message["is_printing"].lower() == "true",
                "heating": message["is_heating"].lower() == "true",
                "paused": message["is_paused"].lower() == "true"
            }
            #self.desktop_notification(old_states)

        if message['event'] == "material_change":
            self.material = message['material'].lower()
        if message['event'] == "nozzle_change":
            self.nozzle = message['nozzle']
        if message['event'] == "start_print":
            self.printingFile = message["filename"]
            self.estimatedTime = message["estimated_time"]
            # Resurrected file has its elapsed time set according to percentage
            self.elapsedTime = 0 if "elapsed_time" not in message else float(message["elapsed_time"])
            self.startTime = time.time() - self.elapsedTime
        if message['event'] == "pin_change":
            self.hasPin = message["has_pin"].lower() == "true"
        if message['event'] == "spool_data_change":
            self.hasNFCSpool = message["has_nfc_spool"].lower() == "true"
            self.filamentRemaining = float(message["filament_remaining"])
            self.filamentColor = message["filament_color"]
        if message['event'] == "new_name":
            self.setName(message['name'])

        # emit new machine after updating attributes with hello message
        if message['event'] == "hello":
            self.emit({"type": "open"})

        eventMessage = {"type": "new_message", "message": message}
        self.emit(eventMessage)

    def onError(self, errorCode):
        Logger.log("w", "error connecting device: %s - [%s]" % (self.ip, self.socket.errorString()))

    def close(self):
        Logger.log("i", "closing - %s[%s]" % (self.name, self.ip))
        self.emit({"type": "close"})
        self.socket.close()
    # end of connection related

    def setName(self, newName):
        self.name = tool.translateChars(newName) if self.isLite else newName

    def getStates(self):
        return tool.merge_two_dicts(self.__states, {"uploading": self.uploader is not None and self.uploader.isUploading()})

    # commands
    def changeName(self, newName):
        self.setName(newName)
        self.write({"request": "change_name", "name": self.name})

    def sayHi(self):
        self.write({"request": "say_hi"})

    def startPreheat(self):
        self.write({"request": "start_preheat"})

    def togglePreheat(self):
        self.write({"request": "toggle_preheat"})

    def pause(self, pin=None):
        self.write({"request": "pause", "pin": pin})

    def resume(self):
        self.write({"request": "resume"})

    def cancel(self, pin=None):
        self.write({"request": "cancel", "pin": pin})

    def fwUpdate(self):
        self.write({"request": "fw_update"})

    def filamentUnload(self):
        self.write({"request": "filament_unload"})

    def upload(self, filename):
        if self.uploader is not None and self.uploader.isUploading():
            return
        self.startPreheat()
        self.uploader = FTPUploader(filename, self.ip, self.ftpPort, self.isLite, self.nonTLS, self.deviceModel)
        self.uploader.uploadEvent.connect(self.uploadProgressCB)
        Logger.log("d", "starting to upload %s" % filename)
        self.uploader.daemon = True
        self.uploader.start()
        # X1+ hack start
        # X1+ doesn't inform back about preheat so just emit an state update
        eventMessage = {"type": "new_message", "message": {"event": "states_update"}}
        self.emit(eventMessage)
        # X1+ hack end

    # end of commands

    def uploadProgressCB(self, progress):
        self.machineUploadEvent.emit(NetworkMachineUploadEventArgs(self, progress))

    def startTimeout(self):
        if self.timer is None:
            self.timer = QtCore.QTimer()
            self.timer.timeout.connect(self.close)
        self.timer.start(self.timeout)

    def write(self, message):
        try:
            self.socket.sendTextMessage(json.dumps(message))
        except Exception as e:
            #Logger.log("w", traceback.format_exc())
            self.close()


    def emit(self, eventData):
        self.machineEvent.emit(NetworkMachineEventArgs(self, eventData))

class FTPUploader(QThread, QObject):

    uploadEvent = pyqtSignal(int)

    def __init__(self, filename, ip, port, isLite, nonTLS, filenameSuffix, parent = None):
        QObject.__init__(self)
        self.ftp = ftplib.FTP() if nonTLS else ftplib.FTP_TLS()
        self.currentSize = 0
        self.totalSize = 0
        self.filename = filename
        self.suffix = filenameSuffix
        self.ip = ip
        self.port = port
        self.progressHandler = None
        self.finishHandler = None
        self.cancel = False
        self.finished = False
        self.nonTLS = nonTLS
        self.isLite = isLite

    def isUploading(self):
        return not self.cancel and not self.finished

    def run(self):
        self.startUpload()

    def stop(self):
        self.cancel = True

    def startUpload(self):
        try:
            callback = lambda buf: self.onProgress(buf)
            self.currentSize = 0
            self.totalSize = os.path.getsize(self.filename)
            self.ftp.connect(self.ip, self.port)
            if not self.nonTLS: # no authentication for some series
                self.ftp.auth()
                self.ftp.prot_p()
            self.ftp.login("zaxe", "zaxe")
            filePtr = open(self.filename, 'rb')
            filename = tool.baseName(self.filename)
            # Now it has long file support
            #filename = tool.eightDot3Filename(filename, "LITE") if self.isLite else filename
            self.ftp.storbinary("stor " + filename, filePtr, io.DEFAULT_BUFFER_SIZE, callback)
            self.ftp.close()
            self.finished = True
        except Exception as e:
            Logger.log("w", traceback.format_exc())

    def onProgress(self, buf):
        if self.cancel:
            try:
                self.ftp.abort()
            except ValueError:
                pass
            except AttributeError:
                pass
            self.ftp.close()
            return
        self.currentSize += len(buf)
        self.uploadEvent.emit(100 * self.currentSize / self.totalSize)

class NetworkMachineContainer():

    machineList = dict()

    def addMachine(self, ip, port, name):
        if len([machine for machine in iter(self.machineList.values()) if machine.ip == ip]) == 0:
            machine = NetworkMachine(ip, port, name)
            Logger.log("d", "adding machine: %s [%s]" % (name, machine.ip))
            machine.daemon = True
            machine.machineEvent.connect(self.onMachineEvent)
            self.machineList[machine.id] = machine
            machine.start()
            return machine
        return None

    def removeMachine(self, machine):
        if machine.id in self.machineList:
            del self.machineList[machine.id]

    def onMachineEvent(self, event):
        if event.message['type'] == "close":
            self.removeMachine(event.machine)

    def closeAll(self):
        for key, machine in self.machineList.iteritems():
            machine.close()


