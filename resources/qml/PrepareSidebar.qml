// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Rectangle
{
    id: prepareSidebar

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_tpu": "Zaxe FLEX",
        "custom": "Custom"
    }

    property var helpStageIndex: 1

    property int currentModeIndex

    property variant printDuration: PrintInformation.currentPrintTime
    property variant printMaterialLengths: PrintInformation.materialLengths
    property variant printMaterialWeights: PrintInformation.materialWeights
    property variant printMaterialCosts: PrintInformation.materialCosts
    property variant printMaterialNames: PrintInformation.materialNames

    color: UM.Theme.getColor("sidebar")
    UM.I18nCatalog { id: catalog; name:"cura"}

    MouseArea
    {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons

        onWheel:
        {
            wheel.accepted = true;
        }
    }

    function switchView(index) {
        try {
            sidebarContents.replace(modesListModel.get(index).item)
            currentModeIndex = index
        } catch (error) {}
    }

    SidebarHeader {
        id: header
        visible: machineExtruderCount.properties.value > 1 || Cura.MachineManager.hasMaterials || Cura.MachineManager.hasVariants
        anchors.top: parent.top
    }

    StackView
    {
        id: sidebarContents

        anchors.bottom: prepareSidebar.bottom
        anchors.top: header.bottom
        anchors.left: prepareSidebar.left
        anchors.right: prepareSidebar.right
        replaceEnter: Transition {
            PropertyAnimation {
                property: "x"
                from: 500
                to: 0
                duration: 200
                easing.type: Easing.InOutBounce
                easing.overshoot: 2
            }
        }

        replaceExit: Transition {
            PropertyAnimation {
                property: "x"
                from: 0
                to: 500
                duration: 200
                easing.type: Easing.InOutBounce
                easing.overshoot: 2
            }
        }
    }

    ListModel
    {
        id: modesListModel
    }

    SidebarDefault
    {
        id: sidebarDefault
        visible: false
    }

    SidebarCustomMaterialSettings
    {
        id: sidebarCustomMaterialSettings
        visible: false
    }

    Component.onCompleted:
    {
        modesListModel.append({
            item: sidebarDefault
        })
        modesListModel.append({
            item: sidebarCustomMaterialSettings
        })

        sidebarContents.replace(modesListModel.get(prepareSidebar.currentModeIndex).item, { "immediate": true })

        currentModeIndex = 0
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStack: Cura.MachineManager.activeMachine
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }
}
