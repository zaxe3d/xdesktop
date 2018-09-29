# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import pyqtSignal, pyqtProperty, QObject, QVariant  # For communicating data and events to Qt.
from UM.FlameProfiler import pyqtSlot

import cura.CuraApplication # To get the global container stack to find the current machine.
from UM.Logger import Logger

from cura.Utils.NetworkMachine import NetworkMachine, NetworkMachineContainer
from typing import Dict
from cura.Utils import BroadcastReceiver

##  Manages zaxe network printers
class NetworkMachineManager(QObject):

    networkMachineContainer = NetworkMachineContainer()
    machineList = dict()

    hasMachine = False

    ##  Signal to notify other components when the list of extruders for a machine definition changes.
    machineListChanged = pyqtSignal()

    ##  Registers listeners and such to listen and command network printers
    def __init__(self, parent = None):
        if NetworkMachineManager.__instance is not None:
            raise RuntimeError("Try to create singleton '%s' more than once" % self.__class__.__name__)
        NetworkMachineManager.__instance = self

        super().__init__(parent)

        self._application = cura.CuraApplication.CuraApplication.getInstance()
        self._initBroadcastReceiver()

    def _initBroadcastReceiver(self) -> None:
        self.broadcastReceiver = BroadcastReceiver.BroadcastReceiver()
        self.broadcastReceiver.broadcastReceived.connect(self._broadcastReceived)

    def _broadcastReceived(self, message) -> None:
        try:
            message['port']
        except:
            message['port'] = 9294
        #Logger.log("d", "ip: %s" % message['ip'])
        machine = self.networkMachineContainer.addMachine(message['ip'], message['port'], message['id'])

        if machine is not None:
            machine.machineEvent.connect(self._onMachineMessage)

    def _onMachineMessage(self, eventArgs) -> None:
        Logger.log("d", "_onMachineMessage: %s" % eventArgs.message)
        try:
            if eventArgs.message['type'] == "open":
                self.machineList[str(eventArgs.machine.id)] = eventArgs.machine
                self.machineListChanged.emit()
            elif eventArgs.message['type'] == "close":
                del self.machineList[eventArgs.machine.id]
                self.machineListChanged.emit()

            self.hasMachine = len(self.printerList) >= 0.
        except AttributeError:
            pass

    @pyqtProperty("QVariantList", notify = machineListChanged)
    def printerList(self) -> Dict[QVariant, str]:
        return self.machineList

    ##  Gets a dict with the extruder stack ids with the extruder number as the key.
    #@pyqtProperty("QVariantMap", notify = printerListChanged)
    #def getPrinterList(self) -> Dict:
    #    return self.printerList

    ## Says Hi on intended machine
    @pyqtSlot(str)
    def SayHi(self, mID) -> None:
        machine = self.machineList[str(mID)]
        Logger.log("d", "Saying Hi on [%s]" % machine.ip)
        machine.sayHi()

    __instance = None   # type: NetworkMachineManager

    @classmethod
    def getInstance(cls, *args, **kwargs) -> "NetworkMachineManager":
        return cls.__instance
