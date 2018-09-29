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
    IDRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    IPRole = Qt.UserRole + 3

    def __init__(self, parent = None):
        super().__init__(parent)

        self.addRoleName(self.IDRole, "mID")
        self.addRoleName(self.NameRole, "mName")
        self.addRoleName(self.IPRole, "mIP")

        self._application = Application.getInstance()
        self._machine_manager = self._application.getNetworkMachineManager()

        self._machine_manager.machineListChanged.connect(self._update)

    def _update(self):
        Logger.log("d", "Updating {model_class_name}.".format(model_class_name = self.__class__.__name__))

        networkMachineList = self._machine_manager.printerList
        Logger.log("w", "machineList count: %d" % len(networkMachineList))

        item_list = []
        for key in networkMachineList:
            networkMachine = networkMachineList[key]
            Logger.log("w", "machineList count: %s" % networkMachine.id)

            item = {
                "mID": networkMachine.id,
                "mName": networkMachine.name,
                "mIP": networkMachine.ip,
            }

            item_list.append(item)

        self.setItems(item_list)
