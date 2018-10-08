// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Rectangle
{
    id: base

    color: "black"
    UM.I18nCatalog { id: catalog; name:"cura"}

    FontLoader { id: zaxeIconFont; source: "../fonts/zaxe.ttf" }
    FontLoader { id: fontAwesomeSolid; source: "../fonts/fa-solid-900.ttf" }

    MouseArea {
        anchors.fill: parent
        onWheel: nMachineList.flick(0, wheel.angleDelta.y * 5)
    }

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_tpu": "Zaxe FLEX",
        "custom": "Custom"
    }

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

    function toHHMMSS(str) {
        var sec_num = parseInt(str, 10); // don't forget the second param
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
        var seconds = sec_num - (hours * 3600) - (minutes * 60);

        if (minutes < 10) { minutes = "0" + minutes; }
        if (seconds < 10) { seconds = "0" + seconds }
        return hours+':'+minutes+':'+seconds;
    }

    Component.onCompleted: {
       var idx, item, count
       // draw list items here. If previously added
       count = Cura.NetworkMachineListModel.rowCount()
       noPrinterWarning.visible = count == 0

       for(idx = 0; idx < count; idx++) {
           item = Cura.NetworkMachineListModel.getItem(idx)
           machineListModel.append(item)
       }
    }

    Connections
    {
        target: Cura.NetworkMachineListModel
        onItemAdded: {
            noPrinterWarning.visible = false
            machineListModel.onAdded(arguments[0]) }
        onItemRemoved: {
            machineListModel.onRemoved(arguments[0])
            if (machineListModel.count == 0)
                noPrinterWarning.visible = true
        }
    }

    ListModel
    {
        id: machineListModel

        function onAdded(idx)
        {
            var item = Cura.NetworkMachineListModel.getItem(idx)

            console.log("adding machine" + item.mName)
            machineListModel.append(item)
        }

        function onRemoved(idx)
        {
            console.log("removing machine" + idx)
            machineListModel.remove(idx)
        }
    }

    Rectangle
    {
        id: page
        color: "#212121"
        anchors.fill: parent
    }

    Rectangle
    {
        id: "noPrinterWarning"
        width: base.width - 20
        height: 150
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 20 }
        color: "#212121"
        Image {
            antialiasing: true
            width: 137; height: 49
            anchors.horizontalCenter: parent.horizontalCenter
            id: noPrinterWarningImage
            source: "../images/connect_your_zaxe.png"
        }

        Label
        {
            anchors.centerIn: parent
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"; font.pointSize: 14; font.bold: true
            text: "Can not find a Zaxe on the network"
        }
    }

    Component
    {
        id: nMachineListDelegate
        NetworkMachine {
            uid: mID
            name: mName
            ip: mIP
            material: mMaterial
            nozzle: mNozzle
            deviceModel: mDeviceModel
            fwVersion: mFWVersion
            printingFile: mPrintingFile
            elapsedTime: mElapsedTime
            estimatedTime: mEstimatedTime
            hasPin: mHasPin

            machineStates: mStates
        }
    }

    ListView
    {
        id: nMachineList

        ScrollBar.vertical: ScrollBar {
            active: true
            clip: true
            Component.onCompleted: x = base.width - width - parent.x
        }

        x: 10; anchors.top: page.top; anchors.bottomMargin: 20; anchors.topMargin: 20
        height: page.height - 20
        model: machineListModel
        delegate: nMachineListDelegate
    }

}
