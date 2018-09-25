# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import pyqtSignal, pyqtProperty, QObject, QVariant  # For communicating data and events to Qt.
from UM.FlameProfiler import pyqtSlot

import cura.CuraApplication # To get the global container stack to find the current machine.
from cura.Settings.GlobalStack import GlobalStack
from UM.Logger import Logger

from typing import Dict

##  Manages zaxe network printers
class NetworkMachineManager(QObject):

    ##  Registers listeners and such to listen and command network printers
    def __init__(self, parent = None):
        if NetworkMachineManager.__instance is not None:
            raise RuntimeError("Try to create singleton '%s' more than once" % self.__class__.__name__)
        NetworkMachineManager.__instance = self

        super().__init__(parent)

        self._application = cura.CuraApplication.CuraApplication.getInstance()

    ##  Signal to notify other components when the list of extruders for a machine definition changes.
    newMachine = pyqtSignal(QVariant)

    ##  Gets a dict with the extruder stack ids with the extruder number as the key.
    @pyqtProperty("QVariantMap", notify = newMachine)
    def extruderIds(self) -> Dict[str, str]:
        extruder_stack_ids = {}  # type: Dict[str, str]

        global_container_stack = self._application.getGlobalContainerStack()
        if global_container_stack:
            extruder_stack_ids = {position: extruder.id for position, extruder in global_container_stack.extruders.items()}

        return extruder_stack_ids

    ##  Changes the active extruder by index.
    #
    #   \param index The index of the new active extruder.
    @pyqtSlot()
    def SayHi(self) -> None:
        Logger.log("e", "Saying Hi")

    __instance = None   # type: NetworkMachineManager

    @classmethod
    def getInstance(cls, *args, **kwargs) -> "NetworkMachineManager":
        return cls.__instance
