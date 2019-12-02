// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

Menu
{
    id: extruderMenu

    property bool extruder1Enabled: Cura.MachineManager.getExtruder(0).isEnabled
    property bool extruder2Enabled: Cura.MachineManager.getExtruder(1).isEnabled

    MenuItem {
        text: catalog.i18nc("@action:inmenu", (extruderMenu.extruder1Enabled ? "Disable" : "Enable") + " Right Extruder")
        onTriggered: Cura.MachineManager.setExtruderEnabled(0, !extruderMenu.extruder1Enabled)
        enabled: !(!extruderMenu.extruder2Enabled && extruderMenu.extruder1Enabled)
    }

    MenuItem {
        text: catalog.i18nc("@action:inmenu", (extruderMenu.extruder2Enabled ? "Disable" : "Enable") + " Left Extruder")
        onTriggered: Cura.MachineManager.setExtruderEnabled(1, !extruderMenu.extruder2Enabled)
        enabled: !(!extruderMenu.extruder1Enabled && extruderMenu.extruder2Enabled)
    }
}
