# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import pyqtSignal, pyqtProperty, QObject, QVariant  # For communicating data and events to Qt.
from UM.FlameProfiler import pyqtSlot

from UM.Logger import Logger
from UM.PluginRegistry import PluginRegistry # To get the Zaxe Code writer.

from cura.Utils.NetworkMachine import NetworkMachine, NetworkMachineContainer
from typing import Dict
from cura.Utils import BroadcastReceiver

from cura.Utils.ZaxeVersion import ZaxeVersion


##  Manages zaxe network printers
class NetworkMachineManager(QObject):

    networkMachineContainer = NetworkMachineContainer()
    machineList = dict()

    hasMachine = False

    ##  Signals to notify other components when the list of extruders for a machine definition changes.
    machineAdded = pyqtSignal(QVariant)
    machineRemoved = pyqtSignal(str)
    machineNewMessage = pyqtSignal(QVariant)
    machineUploadProgress = pyqtSignal(QVariant)


    DEVICE_VERSIONS = {
        "x1": {"version": [0, 0, 0], "path": "/firmware.json"},
        "x1plus": {"version": [0, 0, 0], "path": "/x1plus/firmware.json"},
        "x2": {"version": [0, 0, 0], "path": "/x2/firmware.json"},
        "z1": {"version": [0, 0, 0], "path": "/z1/firmware.json"},
        "z1plus": {"version": [0, 0, 0], "path": "/z1/firmware.json"},
        "z3": {"version": [0, 0, 0], "path": "/z3/firmware.json"},
        "z3plus": {"version": [0, 0, 0], "path": "/z3/firmware.json"},
        "zlite": {"version": [0, 0, 0], "path": "/z3/firmware.json"}
    }

    ##  Registers listeners and such to listen and command network printers
    def __init__(self, parent = None):
        if NetworkMachineManager.__instance is not None:
            raise RuntimeError("Try to create singleton '%s' more than once" % self.__class__.__name__)
        NetworkMachineManager.__instance = self

        super().__init__(parent)

        self._initBroadcastReceiver()

        # Gather firmware version data.
        self._checkDeviceVersions()


    # Firmware version start
    def _checkDeviceVersions(self):
        Logger.log("d", "Generating firmware version info table")
        for k, v in self.DEVICE_VERSIONS.items():
            t = ZaxeVersion(v["path"], k)
            t.versionEvent.connect(self._onReceiveVersion)
            t.run()

    fwDataReceivedCount = 0
    fwVersionDataReady = False
    def _onReceiveVersion(self, event):
        self.DEVICE_VERSIONS[event.deviceModel]["version"] = event.version
        self.fwDataReceivedCount += 1
        if self.fwDataReceivedCount >= len(self.DEVICE_VERSIONS):
            self.fwVersionDataReady = True
    # Firmware version end

    def _initBroadcastReceiver(self) -> None:
        self.broadcastReceiver = BroadcastReceiver.BroadcastReceiver()
        self.broadcastReceiver.broadcastReceived.connect(self._broadcastReceived)

    def _broadcastReceived(self, message) -> None:
        try:
            message['port']
        except:
            message['port'] = 9294
        machine = self.networkMachineContainer.addMachine(message['ip'], message['port'], message['id'])

        if machine is not None:
            machine.machineEvent.connect(self._onMessage)
            machine.machineUploadEvent.connect(self._onUpload)

    def _onMessage(self, eventArgs) -> None:
        #Logger.log("d", "%s - [%s]: %s" % (eventArgs.machine.name, eventArgs.machine.ip, eventArgs.message))
        try:
            if eventArgs.message['type'] == "open":
                self.machineList[str(eventArgs.machine.id)] = eventArgs.machine
                self.machineAdded.emit(eventArgs.machine)
            elif eventArgs.message['type'] == "close" and eventArgs.machine.id in self.machineList.keys():
                del self.machineList[eventArgs.machine.id]
                self.machineRemoved.emit(eventArgs.machine.id)
            elif eventArgs.message['type'] == "new_message":
                self.machineNewMessage.emit(eventArgs)

            self.hasMachine = len(self.printerList) >= 0.
        except AttributeError:
            pass

    def _onUpload(self, eventArgs) -> None:
        try:
            self.machineUploadProgress.emit(eventArgs)
        except AttributeError:
            pass

    @pyqtSlot(str)
    def CreateManualMachine(self, ip) -> None:
        machine = self.networkMachineContainer.addMachine(ip, 9294, "Zaxe")

        if machine is not None:
            machine.machineEvent.connect(self._onMessage)
            machine.machineUploadEvent.connect(self._onUpload)

    @pyqtSlot(str)
    def RemoveManualMachine(self, ip) -> None:
        for mID in self.machineList.keys():
            machine = self.machineList[mID]
            if machine.ip == ip:
                machine.close()
                del self.machineList[machine.id]
                self.machineRemoved.emit(machine.id)
                break

    ## Says Hi on intended machine
    @pyqtSlot(str)
    def SayHi(self, mID) -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "Saying Hi on [%s]" % machine.ip)
        machine.sayHi()

    ## starts to print the scene on intended machine
    @pyqtSlot(str)
    def upload(self, mID) -> bool:
        machine = self.machineList[str(mID)]
        Logger.log("w", "Machine devicemodel [%s - [%s]]" % (machine.name, machine.deviceModel))

        codeGenerator = PluginRegistry.getInstance().getPluginObject(("GCodeWriter" if machine.deviceModel == "zlite" else "ZaxeCodeWriter"))
        success = codeGenerator.generate() 

        if not success:
            Logger.log("w", "Code generation failed for device [%s - [%s]]" % (machine.name, machine.ip))
            return False
        Logger.log("i", "will upload generated code to machine [%s - [%s]]" % (machine.name, machine.ip))
        machine.upload(codeGenerator.getGCodeFile() if machine.deviceModel == "zlite" else codeGenerator.getZaxeFile())
        return True

    ## rename on intended machine
    @pyqtSlot(str, str)
    def ChangeName(self, mID, newName) -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "renaming %s to %s [%s - [%s]]" % (machine.name, newName, machine.name, machine.ip))
        machine.changeName(newName)

    ## toggle preheat on intended machine
    @pyqtSlot(str)
    def TogglePreheat(self, mID) -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "toggling preheat on [%s - [%s]]" % (machine.name, machine.ip))
        machine.togglePreheat()

    ## cancel printing on intended machine
    @pyqtSlot(str, str)
    def Cancel(self, mID, pin = "") -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "canceling printing [%s - [%s]]" % (machine.name, machine.ip))
        machine.cancel(None if pin == "" else pin)

    ## pause printing on intended machine
    @pyqtSlot(str, str)
    def Pause(self, mID, pin = "") -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "pausing [%s - [%s]]" % (machine.name, machine.ip))
        machine.pause(None if pin == "" else pin)

    ## resume printing on intended machine
    @pyqtSlot(str)
    def Resume(self, mID) -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "resuming [%s - [%s]]" % (machine.name, machine.ip))
        machine.resume()

    ## update firmware on intended machine
    @pyqtSlot(str)
    def FWUpdate(self, mID) -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "FW update request sent [%s - [%s]]" % (machine.name, machine.ip))
        machine.fwUpdate()

    ## filament unload on intended machine
    @pyqtSlot(str)
    def FilamentUnload(self, mID) -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "Filament unload request sent [%s - [%s]]" % (machine.name, machine.ip))
        machine.filamentUnload()


    __instance = None   # type: NetworkMachineManager

    @classmethod
    def getInstance(cls, *args, **kwargs) -> "NetworkMachineManager":
        return cls.__instance
