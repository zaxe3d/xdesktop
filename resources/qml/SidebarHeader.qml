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

    UM.I18nCatalog { id: catalog; name:"cura" }

    property int currentExtruderIndex: Cura.ExtruderManager.activeExtruderIndex;
    property var activeExtruder: Cura.MachineManager.activeStack
    property var hasActiveExtruder: activeExtruder != null
    property var currentRootMaterialName: hasActiveExtruder ? materialNames[activeExtruder.material.name] : ""

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_flex": "Zaxe Flex",
        "custom": catalog.i18nc("@label", "Custom")
    }

    spacing: 10

    width: parent.width - UM.Theme.getSize("sidebar_item_margin").width * 2
    anchors {
        top: parent.top
        topMargin: 30
        horizontalCenter: parent.horizontalCenter
    }

    // Title row
    Text {
        id: lblPrintDetails
        text: catalog.i18nc("@label", "Prepare to print")
        color: UM.Theme.getColor("text_sidebar")
        width: parent.width
        font: UM.Theme.getFont("large")
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
            height: 20
            verticalAlignment: Text.AlignBottom
            font: UM.Theme.getFont("large_semi_bold");
            color: UM.Theme.getColor("text_sidebar");
        }

        RowLayout
        {
            id: materialSelectionRow
            spacing: UM.Theme.getSize("sidebar_item_margin").width / 2
            height: 50
            width: parent.width
            anchors.top: materialLabel.bottom
            ExclusiveGroup {
                id: materialGroup
                onCurrentChanged : {
                    Cura.MachineManager.setMaterialById(currentExtruderIndex, current.material)

                    // material specific settings
                    var fanSpeed = 100
                    var coolFanFullLayer = 2
                    var materialPrintTempLayer0 = 220

                    if (current.material == "zaxe_abs") {
                        fanSpeed = 30
                        coolFanFullLayer = 5
                        materialPrintTempLayer0 = 250
                    }

                    if (current.material != "custom") {
                        Cura.MachineManager.setSettingForAllExtruders("material_print_temperature_layer_0", "value", materialPrintTempLayer0)
                    }

                    Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_min", "value", fanSpeed)
                    Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_max", "value", fanSpeed)
                    Cura.MachineManager.setSettingForAllExtruders("cool_fan_full_layer", "value", coolFanFullLayer)

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
                Layout.preferredWidth: 100
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
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignHCenter
                style: UM.Theme.styles.radiobutton
                text: "Zaxe PLA"
            }
            // FLEX
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "zaxe_flex"
                checked: Cura.MachineManager.activeStack.material.name == "zaxe_flex"
                Layout.preferredHeight: 80
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignHCenter
                style: UM.Theme.styles.radiobutton
                text: "Zaxe Flex"
            }
            // Custom
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "custom"
                checked: Cura.MachineManager.activeStack.material.name == "custom"
                Layout.preferredHeight: 80
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignHCenter
                style: UM.Theme.styles.radiobutton
                text: catalog.i18nc("@label", "Custom")
            }
        }

        Button {
            id: customMaterialSettingsButton
            style: UM.Theme.styles.sidebar_simple_button
            text: catalog.i18nc("@label", "Custom material settings")
            visible: prepareSidebar.currentModeIndex == 0 && Cura.MachineManager.activeStack.material.name == "custom"
            anchors {
                top: materialSelectionRow.bottom
                right: parent.right
                topMargin: 3
                rightMargin: -UM.Theme.getSize("sidebar_margin").width
            }
            onClicked: {
                prepareSidebar.switchView(1) // Custom material settings view
            }
        }
    }
    // Bottom Border
    Rectangle { width: parent.width; height: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }

}
