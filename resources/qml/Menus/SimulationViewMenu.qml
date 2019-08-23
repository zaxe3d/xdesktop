// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

Menu
{
    id: menu

    MenuItem
    {
        text: catalog.i18nc("@label", "Show travels")
        checkable: true
        checked: {
            return UM.Preferences.getValue("layerview/show_travel_moves")
        }
        onTriggered: {
            return UM.Preferences.setValue("layerview/show_travel_moves", checked)
        }
    }
}
