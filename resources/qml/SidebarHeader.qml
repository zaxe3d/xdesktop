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

    signal showFirstrunTip(point position, string title, string text, bool nextAvailable, bool imgPath)

    UM.I18nCatalog { id: catalog; name:"cura" }

    property int currentExtruderIndex: Cura.ExtruderManager.activeExtruderIndex;

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_flex": "Zaxe FLEX",
        "zaxe_petg": "Zaxe PETG",
        "custom": catalog.i18nc("@label", "Custom")
    }

    function applyFinalMaterialSettings() {
        // Apply last material specific settings here
        var currentMaterial = Cura.MachineManager.activeStack.material.name
        var fanSpeed = 100
        var coolFanFullLayer = 2
        var materialPrintTempLayer0 = 220

        if (currentMaterial == "zaxe_abs") {
            fanSpeed = 30
            coolFanFullLayer = 5
            materialPrintTempLayer0 = 250
        } else if (currentMaterial == "zaxe_petg") {
            fanSpeed = 60
            materialPrintTempLayer0 = 240
        }

        if (currentMaterial != "custom") {
            Cura.MachineManager.setSettingForAllExtruders("material_print_temperature_layer_0", "value", materialPrintTempLayer0)
            if (currentMaterial.indexOf("zaxe_flex") > -1) {
                Cura.MachineManager.setSettingForAllExtruders("retraction_combing", "value", "all")
                Cura.MachineManager.setSettingForAllExtruders("material_flow", "value", 105)
            } else {
                Cura.MachineManager.resetSettingForAllExtruders("material_flow")
                Cura.MachineManager.resetSettingForAllExtruders("retraction_combing")
            }
        }

        Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_min", "value", fanSpeed)
        Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_max", "value", fanSpeed)
        Cura.MachineManager.setSettingForAllExtruders("cool_fan_full_layer", "value", coolFanFullLayer)
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
        id: materialGrid
        width: parent.width
        height: 130
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

        GridLayout
        {
            id: materialSelectionGrid
            width: parent.width
            columns: 3
            columnSpacing: 5
            rowSpacing: 5
            anchors.top: materialLabel.bottom
            ExclusiveGroup {
                id: materialGroup
                onCurrentChanged : {
                    if (current.material == "zaxe_flex") {
                        var flexMaterialObj = materialSubModel.get(flexSubMaterialCombobox.currentIndex)
                        Cura.MachineManager.setMaterialById(currentExtruderIndex, flexMaterialObj.material)
                    } else {
                        Cura.MachineManager.setMaterialById(currentExtruderIndex, current.material)
                    }

                    if (UM.Preferences.getValue("general/firstrun"))
                        UM.Preferences.setValue("general/firstrun_step", 6)
                }
            }
            // ABS
            RadioButton
            {
                // can't get the id of the current item from onCurrentChanged so I created another field
                exclusiveGroup: materialGroup
                property string material : "zaxe_abs"
                checked: Cura.MachineManager.activeStack.material.name == "zaxe_abs"
                Layout.preferredHeight: 50
                Layout.preferredWidth: 90
                Layout.leftMargin: 10
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: "Zaxe ABS"
            }
            // PLA
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "zaxe_pla"
                checked: Cura.MachineManager.activeStack.material.name == "zaxe_pla"
                Layout.preferredHeight: 50
                Layout.preferredWidth: 90
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: "Zaxe PLA"
            }
            // FLEX
            RadioButton
            {
                id: rBMaterialFlex
                exclusiveGroup: materialGroup
                property string material : "zaxe_flex"
                checked: Cura.MachineManager.activeStack.material.name.indexOf("zaxe_flex") > -1
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: "Zaxe FLEX"
            }
            // PETG
            RadioButton
            {
                // can't get the id of the current item from onCurrentChanged so I created another field
                exclusiveGroup: materialGroup
                property string material : "zaxe_petg"
                checked: Cura.MachineManager.activeStack.material.name == "zaxe_petg"
                Layout.preferredHeight: 30
                Layout.preferredWidth: 90
                Layout.leftMargin: 10
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: "Zaxe PETG"
            }
            // Custom
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "custom"
                checked: Cura.MachineManager.activeStack.material.name == "custom"
                Layout.preferredHeight: 30
                Layout.preferredWidth: 90
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: catalog.i18nc("@label", "Custom")
            }
        }

        ComboBox // Flex sub material
        {
            id: flexSubMaterialCombobox
            visible: Cura.MachineManager.activeStack.material.name.indexOf("zaxe_flex") > -1

            width: 95
            height: UM.Theme.getSize("setting_control").height

            x: rBMaterialFlex.x + 19
            anchors {
                top: materialSelectionGrid.bottom
                topMargin: -48
            }

            ListModel {
                id: materialSubModel
            }

            Component.onCompleted: {
                // i18 doesn't work directly when declaring items within model bug!
                materialSubModel.append({ material: "zaxe_flex_white", color: "white", text: catalog.i18nc("@color", "White") })
                materialSubModel.append({ material: "zaxe_flex_black", color: "black", text: catalog.i18nc("@color", "Black") })

                if (Cura.MachineManager.activeStack.material.name.indexOf("zaxe_flex") > -1) {
                    currentIndex = Cura.MachineManager.activeStack.material.name == "zaxe_flex_white" ? 0 : 1
                    var matObj = materialSubModel.get(index)
                    color = matObj.color

                }
            }

            model: materialSubModel

            property string color: {
                if (currentIndex < 0) {
                    return "white" // return the first one from the list. Only needed for init
                }
                return materialSubModel.get(currentIndex).color
            }
            property string color_override: ""  // for manually setting values

            textRole: "text"  // this solves that the combobox isn't populated in the first time XDesktop is started

            Behavior on height { NumberAnimation { duration: 100 } }

            style: UM.Theme.styles.combobox_color

            onActivated:
            {
                var matObj = materialSubModel.get(index)
                Cura.MachineManager.setMaterialById(currentExtruderIndex, matObj.material)
                color = matObj.color
            }


            // Disable mouse wheel for combobox
            MouseArea {
                anchors.fill: parent
                onWheel: {
                    // do nothing
                }
                onPressed: {
                    // propogate to ComboBox
                    mouse.accepted = false;
                }
                onReleased: {
                    // propogate to ComboBox
                    mouse.accepted = false;
                }
            }
        }

        Button {
            id: customMaterialSettingsButton
            style: UM.Theme.styles.sidebar_simple_button
            text: catalog.i18nc("@label", "Custom material settings")
            visible: prepareSidebar.currentModeIndex == 0 && Cura.MachineManager.activeStack.material.name == "custom"
            anchors {
                top: materialSelectionGrid.bottom
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

    Connections
    {
        target: Cura.MachineManager
        onActiveQualityChanged:
        {
            // Apply on every material change and quality change
            applyFinalMaterialSettings()
        }
    }

    Connections {
        target: UM.Preferences
        onPreferenceChanged:
        {
            if (UM.Preferences.getValue("general/firstrun")) {
                switch(UM.Preferences.getValue("general/firstrun_step")) {
                    case 5:
                        base.showFirstrunTip(
                            materialSelectionGrid.mapToItem(base, 0, Math.round(materialSelectionGrid.height / 2) - 65),
                            catalog.i18nc("@firstrun", "Material Selection"),
                            catalog.i18nc("@firstrun", "Select the material currently installed on your Zaxe"), true, "")
                        break
                }
            }
        }
    }
}

