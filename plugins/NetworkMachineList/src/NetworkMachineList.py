# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.
import os.path
from typing import Optional
from UM.Logger import Logger
from UM.Application import Application
from UM.Resources import Resources
from cura.Stages.CuraStage import CuraStage
from PyQt5.QtCore import pyqtSlot, QObject
from UM.PluginRegistry import PluginRegistry


from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")

##  Stage for selecting / showing network printer(s)
class NetworkMachineList(CuraStage, QObject):
    def __init__(self, parent = None):
        QObject.__init__(self, parent)
        CuraStage.__init__(self)
        Application.getInstance().engineCreatedSignal.connect(self._engineCreated)

    def _engineCreated(self):
        plugin_path = PluginRegistry.getInstance().getPluginPath(self.getPluginId())
        sidebar_component_path = path = os.path.join(plugin_path, "resources", "qml", "NetworkMachineList.qml")
        self.addDisplayComponent("sidebar", sidebar_component_path)
