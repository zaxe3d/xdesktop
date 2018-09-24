// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura
import "Menus"
import "Menus/ConfigurationMenu"

Rectangle
{
    id: base

    property bool printerConnected: Cura.MachineManager.printerConnected

    color: "black"
    UM.I18nCatalog { id: catalog; name:"cura"}

    FontLoader { id: zaxeIconFont; source: "../fonts/zaxe.ttf" }

    Timer {
        id: tooltipDelayTimer
        interval: 500
        repeat: false
        property var item
        property string text

        onTriggered:
        {
            base.showTooltip(base, {x: 0, y: item.y}, text);
        }
    }

    function showTooltip(item, position, text)
    {
        tooltip.text = text;
        position = item.mapToItem(base, position.x - UM.Theme.getSize("default_arrow").width, position.y);
        tooltip.show(position);
    }

    function hideTooltip()
    {
        tooltip.hide();
    }

    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons

        onWheel:
        {
            wheel.accepted = true;
        }
    }

    Rectangle
    {
        id: page
        color: "#212121"
        anchors.fill: parent
    }

    Grid {
        id: nMMachineList
        x: 10; anchors.top: page.top; anchors.bottomMargin: 20; anchors.topMargin: 20
        rows: 2; columns: 1

        NetworkMachine { }
        NetworkMachine { }
        NetworkMachine { }
    }

}
