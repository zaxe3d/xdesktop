# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import Qt

from UM.Application import Application
from UM.Logger import Logger
from UM.Qt.ListModel import ListModel

from cura.NetworkMachineManager import NetworkMachineManager

#
# QML Model for all built-in quality profiles. This model is used for the drop-down quality menu.
#
class NetworkMachineListModel(ListModel):
    NameRole = Qt.UserRole + 1

    def __init__(self, parent = None):
        super().__init__(parent)

        self.addRoleName(self.NameRole, "name")

        self._application = Application.getInstance()
        self._machine_manager = self._application.getNetwork.MachineManager()

        self._machine_manager.machineListChanged.connect(self._update)

        self._update()

    def _update(self):
        Logger.log("d", "Updating {model_class_name}.".format(model_class_name = self.__class__.__name__))

        networkMachineList = self._machine_manager.printerList

        item_list = []
        for key in networkMachineList:
            networkMachine = networkMachineList[key]

            item = {"name": networkMachine.name}

            item_list.append(item)

        self.setItems(item_list)
