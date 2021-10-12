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

    property int extruderIndex: Cura.ExtruderManager.activeExtruderIndex;

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_flex": "Zaxe FLEX",
        "zaxe_petg": "Zaxe PETG",
        "basf_asa": "BASF ASA",
        "basf_pet_cf15": "BASF PET CF15",
        "custom": catalog.i18nc("@label", "Custom")
    }

    function setMaterial(material) {
        Cura.MachineManager.setMaterialById(0, material)
        // All extruders must have the same material
        if (machineExtruderCount.properties.value > 1) {
            Cura.MachineManager.setMaterialById(1, material)
        }
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
        renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                    if (current.material == "basf") { // if sub model is not selected
                        setMaterial(basfSubMaterialModel.get(basfSubMaterialCombobox.currentIndex).value)
                    } else {
                        setMaterial(current.material)
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
                checked: Cura.MachineManager.currentRootMaterialId[0] == material
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
                checked: Cura.MachineManager.currentRootMaterialId[0] == material
                Layout.preferredHeight: 50
                Layout.preferredWidth: 90
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: materialNames[material]
            }
            // FLEX
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "zaxe_flex"
                checked: Cura.MachineManager.currentRootMaterialId[0] == material
                Layout.preferredHeight: 50
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: materialNames[material]
            }
            // PETG
            RadioButton
            {
                // can't get the id of the current item from onCurrentChanged so I created another field
                exclusiveGroup: materialGroup
                property string material : "zaxe_petg"
                checked: Cura.MachineManager.currentRootMaterialId[0] == material
                Layout.preferredHeight: 30
                Layout.preferredWidth: 90
                Layout.leftMargin: 10
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: materialNames[material]
            }
            // BASF
            RadioButton
            {
                id: rBMaterialBasf
                exclusiveGroup: materialGroup
                property string material : "basf"
                checked: Cura.MachineManager.currentRootMaterialId[0].indexOf("basf") > -1
                Layout.preferredHeight: 30
                Layout.preferredWidth: 90
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: "BASF"
            }
            // Custom
            RadioButton
            {
                exclusiveGroup: materialGroup
                property string material : "custom"
                checked: Cura.MachineManager.currentRootMaterialId[0] == material
                Layout.preferredHeight: 30
                Layout.preferredWidth: 90
                Layout.alignment: Qt.AlignLeft
                style: UM.Theme.styles.radiobutton
                text: catalog.i18nc("@label", "Custom")
            }
        }

        ComboBox // BASF sub material
        {
            id: basfSubMaterialCombobox
            visible: rBMaterialBasf.checked

            width: 90
            height: UM.Theme.getSize("setting_control").height

            x: rBMaterialBasf.x + 21

            anchors {
                top: materialSelectionGrid.bottom
                topMargin: -5
            }

            model: ListModel {
                id: basfSubMaterialModel
                ListElement { text: "ASA"; value: "basf_asa" }
                ListElement { text: "PET CF 15"; value: "basf_pet_cf15" }
            }

            textRole: "text"  // this solves that the combobox isn't populated in the first time XDesktop is started

            Behavior on height { NumberAnimation { duration: 100 } }

            style: UM.Theme.styles.combobox

            onActivated: setMaterial(model.get(index).value)

            currentIndex: {
                for(var i = 0; i < basfSubMaterialModel.count; i++) {
                    if(basfSubMaterialModel.get(i).value == Cura.MachineManager.currentRootMaterialId[0]) {
                        return i
                    }
                }
                return 0 // 0 for default
            }
            MouseWheelDisabled {}
        }

        Button {
            id: customMaterialSettingsButton
            style: UM.Theme.styles.sidebar_simple_button
            text: catalog.i18nc("@label", "Custom material settings")
            visible: prepareSidebar.currentModeIndex == 0 &&
                     Cura.MachineManager.currentRootMaterialId[extruderIndex] == "custom"
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

        UM.SettingPropertyProvider
        {
            id: machineExtruderCount

            containerStack: Cura.MachineManager.activeMachine
            key: "machine_extruder_count"
            watchedProperties: [ "value" ]
        }
    }
    // Bottom Border
    Rectangle { width: parent.width; height: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }

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

