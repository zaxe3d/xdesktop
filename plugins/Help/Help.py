# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.
import os.path
from UM.Application import Application
from UM.Resources import Resources
from cura.Stages.CuraStage import CuraStage


##  Stage for displaying help
class Help(CuraStage):

    def __init__(self, parent = None):
        super().__init__(parent)
        Application.getInstance().engineCreatedSignal.connect(self._engineCreated)

    def _engineCreated(self):
        sidebar_component_path = os.path.join(Resources.getPath(Application.getInstance().ResourceTypes.QmlFiles),
                                              "Help.qml")
        self.addDisplayComponent("sidebar", sidebar_component_path)
