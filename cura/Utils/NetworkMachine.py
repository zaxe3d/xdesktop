from PyQt5.QtCore import QUrl, QCoreApplication, QTimer, QObject, pyqtSignal
from PyQt5 import QtCore, QtWebSockets, QtNetwork

from threading import *
import ssl
import json
import os
import io
import ftplib
import traceback
import sys
import uuid
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

class NetworkMachine(QObject, Thread):

    ip = None

    id = None

    ftpPort = 9494

    name = None

    machineEvent = pyqtSignal(NetworkMachineEventArgs)
    machineUploadEvent = pyqtSignal(NetworkMachineUploadEventArgs)

    def __init__(self, ip, port, name, parent = None):
        Thread.__init__(self)
        QObject.__init__(self)
        self.ip = ip
        self.port = port
        self.setName(name)
        self.id = uuid.uuid4().hex
        self.eventHandlers = []
        self.currentLen = 0
        self.networkId = None
        self.fileName = None
        self.currentSize = 0
        self.totalSize = 0
        self.timer = None
        self.uploader = None
        self.nozzle = 0.4
        self.printingFile = ""
        self.estimatedTime = ""
        self.__states = {}
        self.material = ""
        self.deviceModel = "x1"
        self.hasPin = False
        self.elapsedTime = 0
        self.fwVersion = [999, 0, 0]
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
            self.timer.cancel()
        Logger.log("d", "connected: %s" % self.ip)

    def onDisconnected(self):
        if self.uploader is not None:
            self.uploader.stop()
        self.close()

    def onMessage(self, message):
        if self.timer is not None:
            self.timer.cancel()
        self.startTimeout()
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
            try:
                self.printingFile = message["filename"]
                self.elapsedTime = message["elapsed_time"]
                self.estimatedTime = message["estimated_time"]
                self.hasPin = message["has_pin"].lower()
            except:
                self.printingFile = ""
                self.elapsedTime = 0
                self.estimatedTime = ""
                self.hasPin = "false"

        if message['event'] in ["hello", "states_update"]:
            old_states = self.__states

            # backward compatiblity
            calibrating = False
            bedOccupied = False
            if "is_calibrating" in message:
                calibrating = message["is_calibrating"].lower() == "true"
                bedOccupied = message["is_bed_occupied"].lower() == "true"

            self.__states = {
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
            self.elapsedTime = 0
        if message['event'] == "pin_change":
            self.hasPin = message["has_pin"].lower()
        if message['event'] == "new_name":
            self.setName(message['name'])

        # emit new machine after updating attributes with hello message
        if message['event'] == "hello":
            self.emit({"type": "open"})

        eventMessage = {"type": "new_message", "message": message}
        self.emit(eventMessage)

    def onError(self, errorCode):
        Logger.log("w", "error connecting device: %s - [%s]" % (self.ip, errorCode))

    def close(self):
        Logger.log("i", "closing - %s[%s]" % (self.name, self.ip))
        self.emit({"type": "close"})
        self.socket.close()
    # end of connection related

    def setName(self, newName):
        self.name = tool.clearChars(newName)

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

    def upload(self, filename):
        if self.uploader is not None and self.uploader.isUploading():
            return
        self.startPreheat()
        self.uploader = FTPUploader(filename, self.ip, self.ftpPort)
        self.uploader.uploadEvent.connect(self.uploadProgressCB)
        Logger.log("w", "starting to upload")
        self.uploader.daemon = True
        self.uploader.start()

    # end of commands

    def uploadProgressCB(self, progress):
        self.machineUploadEvent.emit(NetworkMachineUploadEventArgs(self, progress))

    def startTimeout(self):
        self.timer = Timer(20, self.close)
        self.timer.start()

    def write(self, message):
        try:
            self.socket.sendTextMessage(json.dumps(message))
        except Exception as e:
            #Logger.log("w", traceback.format_exc())
            self.close()


    def emit(self, eventData):
        self.machineEvent.emit(NetworkMachineEventArgs(self, eventData))

class FTPUploader(QObject, Thread):

    uploadEvent = pyqtSignal(int)

    def __init__(self, filename, ip, port, parent = None):
        Thread.__init__(self)
        QObject.__init__(self)
        self.ftp = ftplib.FTP_TLS()
        self.currentSize = 0
        self.totalSize = 0
        self.filename = filename
        self.ip = ip
        self.port = port
        self.progressHandler = None
        self.finishHandler = None
        self.cancel = False
        self.finished = False

    def isUploading(self):
        return not self.cancel and not self.finished

    def run(self):
        self.startUpload()

    def stop(self):
        self.cancel = True

    def startUpload(self):
        callback = lambda buf: self.onProgress(buf)
        self.currentSize = 0
        self.totalSize = os.path.getsize(self.filename)
        self.ftp.connect(self.ip, self.port)
        self.ftp.auth()
        self.ftp.prot_p()
        self.ftp.login("zaxe", "zaxe")
        filePtr = open(self.filename, 'rb')
        try:
            self.ftp.storbinary("stor " + tool.clearChars(os.path.basename(self.filename)), filePtr, io.DEFAULT_BUFFER_SIZE, callback)
        except ftplib.all_errors:
            pass
        self.ftp.close()
        self.finished = True

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
            Logger.log("d", "adding machine: %s" % name)
            machine = NetworkMachine(ip, port, name)
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


