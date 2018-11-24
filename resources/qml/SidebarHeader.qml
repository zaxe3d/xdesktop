// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.1
import QtGraphicalEffects 1.0

import UM 1.2 as UM
import Cura 1.0 as Cura

import "Menus"

Column
{
    id: base;

    property int currentExtruderIndex: Cura.ExtruderManager.activeExtruderIndex;
    property var activeExtruder: Cura.MachineManager.activeStack
    property var hasActiveExtruder: activeExtruder != null
    property var currentRootMaterialName: hasActiveExtruder ? materialNames[activeExtruder.material.name] : ""

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_tpu": "Zaxe FLEX",
        "custom": "Custom"
    }

    spacing: 7

    signal showTooltip(Item item, point location, string text)
    signal hideTooltip()

    width: parent.width - UM.Theme.getSize("sidebar_item_margin").width * 2
    anchors {
        top: parent.top
        topMargin: 42
        horizontalCenter: parent.horizontalCenter
    }

    // Title row
    Text {
        id: lblPrintDetails
        text: catalog.i18nc("@label", "Prepare to print")
        color: UM.Theme.getColor("text_sidebar_medium")
        width: parent.width
        font: UM.Theme.getFont("xx_large")
        horizontalAlignment: Text.AlignHCenter
    }
    // Bottom Border
    Rectangle { width: parent.width; height: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_extra_dark") }

    Item
    {
        id: materialRow
        width: parent.width
        height: 100
        anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
        anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height

        Label
        {
            id: materialLabel
            text: catalog.i18nc("@label", "Material");
            width: parent.width - UM.Theme.getSize("default_margin").width
            height: UM.Theme.getSize("setting_control").height
            verticalAlignment: Text.AlignVCenter
            font: UM.Theme.getFont("large");
            color: UM.Theme.getColor("text_sidebar");
        }

        RowLayout
        {
            spacing: UM.Theme.getSize("sidebar_item_margin").width / 2
            height: 50
            width: parent.width
            anchors.top: materialLabel.bottom
            ExclusiveGroup {
                id: materialGroup
                onCurrentChanged : {
                    Cura.MachineManager.setMaterialById(currentExtruderIndex, current.material)

                    var fanSpeed = 100
                    if (current.material == "zaxe_abs")
                        fanSpeed = 30

                    Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_min", "value", fanSpeed)
                    Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_max", "value", fanSpeed)
                }
            }
            // ABS
            RadioButton
            {
                // can't get the id of the current item from onCurrentChanged so I created another field
                exclusiveGroup: materialGroup
                property string material : "zaxe_abs"
                checked: Cura.MachineManager.activeStack.material.name == "zaxe_abs"
                Layout.preferredHeight: 80
                Layout.preferredWidth: 80
                Layout.alignment: Qt.AlignHCenter
                style: UM.Theme.styles.radiobutton
                text: "Zaxe ABS"
            }
            // PLA
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "zaxe_pla"
                checked: Cura.MachineManager.activeStack.material.name == "zaxe_pla"
                Layout.preferredHeight: 80
                Layout.preferredWidth: 80
                Layout.alignment: Qt.AlignHCenter
                style: UM.Theme.styles.radiobutton
                text: "Zaxe PLA"
            }
            // Custom
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "custom"
                checked: activeExtruder.material.name == "custom"
                Layout.preferredHeight: 80
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignHCenter
                style: UM.Theme.styles.radiobutton
                text: catalog.i18nc("@label", "Custom")
            }
        }
    }
    // Bottom Border
    Rectangle { width: parent.width; height: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStack: Cura.MachineManager.activeMachine
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.I18nCatalog { id: catalog; name:"cura" }
}
