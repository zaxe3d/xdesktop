// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: networkMachineList

    signal showFirstrunTip(point position, string title, string text, bool nextAvailable, bool imgPath)

    UM.I18nCatalog { id: catalog; name:"cura"}

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_flex": "Zaxe FLEX",
        "zaxe_flex_white": "Zaxe FLEX" + " " + catalog.i18nc("@color", "White"),
        "zaxe_flex_black": "Zaxe FLEX" + " " + catalog.i18nc("@color", "Black"),
        "zaxe_petg": "Zaxe PETG",
        "custom": catalog.i18nc("@label", "Custom")
    }

    property var materialColors : {
        "White": catalog.i18nc("@color", "White"), "Gray": catalog.i18nc("@color", "Gray"),
        "Black": catalog.i18nc("@color", "Black"), "Chocolate": catalog.i18nc("@color", "Chocolate"),
        "Red": catalog.i18nc("@color", "Red"), "Orange": catalog.i18nc("@color", "Orange"),
        "Yellow": catalog.i18nc("@color", "Yellow"), "Blue": catalog.i18nc("@color", "Blue"),
        "Dark Green": catalog.i18nc("@color", "Dark Green"), "Green": catalog.i18nc("@color", "Green"),
        "Purple": catalog.i18nc("@color", "Purple"), "Galaxy Blue": catalog.i18nc("@color", "Galaxy Blue"),
        "Natural": catalog.i18nc("@color", "Natural"), "Silver": catalog.i18nc("@color", "Silver"),
        "Gold": catalog.i18nc("@color", "Gold"), "Glow Blue": catalog.i18nc("@color", "Glow Blue"),
        "Pink": catalog.i18nc("@color", "Pink")
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
       noPrinterWarningTimer.start()
       /*for(idx = 0; idx < count; idx++) {
           // no need for this since it is now using filtering
           item = Cura.NetworkMachineListModel.getItem(idx)
           machineListModel.append(item)
       }*/
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
        onCleared: {
            machineListModel.clear()
            noPrinterWarning.visible = true
        }
    }

    ListModel
    {
        id: machineListModel

        function onAdded(idx)
        {
            machineListModel.append(Cura.NetworkMachineListModel.getItem(idx))
        }

        function onRemoved(idx)
        {
            machineListModel.remove(idx)
        }
    }

    Rectangle
    {
        id: page
        color: UM.Theme.getColor("sidebar")
        anchors.fill: parent
    }

    Rectangle
    {
        Timer {
            id: noPrinterWarningTimer
            interval: 3000; running: false; repeat: false
            onTriggered: {
                noPrinterWarning.visible = Cura.NetworkMachineListModel.rowCount() == 0
            }
        }
        id: noPrinterWarning
        width: networkMachineList.width
        visible: false
        height: 25
        anchors { horizontalCenter: parent.horizontalCenter; top: slicerBar.bottom; topMargin: 20 }
        color: UM.Theme.getColor("sidebar_item_light")
        Image {
            antialiasing: true
            width: 25; height: 25
            source: "../images/no_connection.png"
            anchors.right: noPrinterWarningLabel.left; anchors.rightMargin: 5
        }
        Label
        {
            id: noPrinterWarningLabel
            anchors { centerIn: parent }
            color: UM.Theme.getColor("text_sidebar")
            font: UM.Theme.getFont("large_nonbold")
            text: catalog.i18nc("@label", "Can not find a Zaxe on the network")
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
            startTime: mStartTime
            estimatedTime: mEstimatedTime
            filamentRemaining: mFilamentRemaining
            filamentColor: mFilamentColor
            snapshot: mSnapshot
            hasPin: mHasPin
            hasNFCSpool: mHasNFCSpool
            hasFWUpdate: mHasFWUpdate
            hasSnapshot: mHasSnapshot

            machineStates: mStates
        }
    }


    // SlicerBar is actually the top panel.
    SlicerBar
    {
        id: slicerBar
        anchors.top: parent.top
        anchors.right: parent.right
        onShowFirstrunTip: {
            networkMachineList.showFirstrunTip(slicerBar.mapToItem(networkMachineList, position.x, position.y), title, text, nextAvailable, imgPath)
        }
    }

    // Bottom Border
    Rectangle {
        id: slicerBarBottomBorder
         width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
        height: 2
        color: UM.Theme.getColor("sidebar_item_dark")
        anchors {
            top: slicerBar.bottom
            horizontalCenter: parent.horizontalCenter
        }
        z: 10
    }

    ScrollView
    {
        id: scroller
        anchors.top: slicerBarBottomBorder.bottom;
        anchors.bottom: parent.bottom;
        anchors.right: parent.right;
        anchors.left: parent.left;
        anchors.topMargin: -2
        style: UM.Theme.styles.scrollview;
        flickableItem.flickableDirection: Flickable.VerticalFlick

        ListView
        {
            id: nMachineList

            leftMargin: 10; bottomMargin: 15
            model: machineListModel
            delegate: nMachineListDelegate
            cacheBuffer: 1000000;   // Set a large cache to effectively just cache every list item.
            spacing: -2
        }
    }
}
