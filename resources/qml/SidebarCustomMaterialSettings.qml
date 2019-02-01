// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: base

    property var lastSelectedMaterial: ""
    property var customMaterialSelected: Cura.MachineManager.activeStack.material.name == "custom"

    onCustomMaterialSelectedChanged:  {
        // apply custom settings here
        if (customMaterialSelected) {
            Cura.MachineManager.setSettingForAllExtruders("material_print_temperature", "value", UM.Preferences.getValue("custom_material/material_print_temperature"))
            Cura.MachineManager.setSettingForAllExtruders("material_print_temperature_layer_0", "value", UM.Preferences.getValue("custom_material/material_print_temperature"))
            Cura.MachineManager.setSettingForAllExtruders("material_bed_temperature", "value", UM.Preferences.getValue("custom_material/material_bed_temperature"))
            Cura.MachineManager.setSettingForAllExtruders("material_bed_temperature_layer_0", "value", UM.Preferences.getValue("custom_material/material_bed_temperature"))

            // speed
            var printSpeedMultiplier = UM.Preferences.getValue("custom_material/print_speed_multiplier")
            speedInfill.setPropertyValue("value", (speedInfill.properties.value / printSpeedMultiplier) * printSpeedMultiplier)
            speedTopbottom.setPropertyValue("value", (speedTopbottom.properties.value / printSpeedMultiplier) * printSpeedMultiplier)
            speedRoofing.setPropertyValue("value", (speedRoofing.properties.value / printSpeedMultiplier) * printSpeedMultiplier)
            speedWall0.setPropertyValue("value", (speedWall0.properties.value / printSpeedMultiplier) * printSpeedMultiplier)
            speedWallX.setPropertyValue("value", (speedWallX.properties.value / printSpeedMultiplier) * printSpeedMultiplier)
            speedSupportRoof.setPropertyValue("value", (speedSupportRoof.properties.value / printSpeedMultiplier) * printSpeedMultiplier)
            speedSupportInfill.setPropertyValue("value", (speedSupportInfill.properties.value / printSpeedMultiplier) * printSpeedMultiplier)
            // end of speed
            Cura.MachineManager.setSettingForAllExtruders("material_flow", "value", UM.Preferences.getValue("custom_material/material_flow"))
            Cura.MachineManager.setSettingForAllExtruders("retraction_speed", "value", UM.Preferences.getValue("custom_material/retraction_speed"))
            var retractionAmount = parseFloat(UM.Preferences.getValue("custom_material/retraction_amount"))
            Cura.MachineManager.setSettingForAllExtruders("retraction_enable", "value", retractionAmount == 0 ? "False" : "True")
            Cura.MachineManager.setSettingForAllExtruders("retraction_amount", "value", retractionAmount)
        } else if (lastSelectedMaterial == "custom") {
            Cura.ContainerManager.clearUserContainers();
            prepareSidebar.switchView(0) // Default view
            // set values coming from preferences back.
            supportEnabled.setPropertyValue("value", parseInt(UM.Preferences.getValue("slicing/support_angle")) > 0)
            supportAngle.setPropertyValue("value", (90 - Math.min(90, parseInt(UM.Preferences.getValue("slicing/support_angle")))))
        }

        lastSelectedMaterial = Cura.MachineManager.activeStack.material.name
    }

    ScrollView
    {
        anchors.fill: parent
        style: UM.Theme.styles.scrollview
        flickableItem.flickableDirection: Flickable.VerticalFlick

        ColumnLayout
        {
            width: parent.parent.width
            anchors.top: parent.top
            anchors.topMargin: Math.round(UM.Theme.getSize("sidebar_margin").height / 2)
            spacing: UM.Theme.getSize("sidebar_spacing").height

            //
            // Custom material settings pane
            //
            Item
            {
                id: customMaterialSettingsPane
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: childrenRect.height
                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: UM.Theme.getSize("sidebar_margin").height

                ColumnLayout
                {
                    width: parent.parent.width
                    spacing: UM.Theme.getSize("sidebar_spacing").height

                    Label
                    {
                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 20
                        Layout.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                        Layout.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                        font: UM.Theme.getFont("large");
                        text: catalog.i18nc("@label", "Custom material settings")
                    }
                    Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2)
; Layout.preferredHeight: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark"); Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height }
                    Item
                    {
                        id: extruderTempRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: extruderTempCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .69)

                                Label
                                {
                                    id: extruderTempLabel
                                    text: catalog.i18nc("@label", "Extruder temperature")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item
                            {
                                id: extruderTempCellRight

                                width: Math.round(base.width * .22)
                                height: extruderTempCellLeft.height

                                anchors.left: extruderTempCellLeft.right
                                anchors.bottom: extruderTempCellLeft.bottom

                                TextField {
                                    width: parent.width
                                    height: UM.Theme.getSize("setting_control").height;
                                    property string unit: "°C";
                                    style: UM.Theme.styles.text_field;
                                    text: parseInt(UM.Preferences.getValue("custom_material/material_print_temperature"))
                                    anchors.verticalCenter: parent.verticalCenter
                                    validator: IntValidator { }

                                    onEditingFinished:
                                    {
                                        UM.Preferences.setValue("custom_material/material_print_temperature", parseInt(text))
                                        Cura.MachineManager.setSettingForAllExtruders("material_print_temperature", "value", parseInt(text))
                                        Cura.MachineManager.setSettingForAllExtruders("material_print_temperature_layer_0", "value", parseInt(text))
                                    }
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: bedTemperatureRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: bedTemperatureCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .69)

                                Label
                                {
                                    id: bedTemperatureLabel
                                    text: catalog.i18nc("@label", "Bed temperature")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item
                            {
                                id: bedTemperatureCellRight

                                width: Math.round(base.width * .22)
                                height: bedTemperatureCellLeft.height

                                anchors.left: bedTemperatureCellLeft.right
                                anchors.bottom: bedTemperatureCellLeft.bottom

                                TextField {
                                    width: parent.width
                                    height: UM.Theme.getSize("setting_control").height;
                                    property string unit: "°C";
                                    style: UM.Theme.styles.text_field;
                                    text: parseInt(UM.Preferences.getValue("custom_material/material_bed_temperature"))
                                    anchors.verticalCenter: parent.verticalCenter
                                    validator: IntValidator { }

                                    onEditingFinished:
                                    {
                                        UM.Preferences.setValue("custom_material/material_bed_temperature", parseInt(text))
                                        Cura.MachineManager.setSettingForAllExtruders("material_bed_temperature", "value", parseInt(text))
                                        Cura.MachineManager.setSettingForAllExtruders("material_bed_temperature_layer_0", "value", parseInt(text))
                                    }
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: chamberTemperatureRow

                        // X1 doesn't have chamber temp setting
                        visible: Cura.MachineManager.activeMachineId != "X1"
                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: chamberTemperatureCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .69)

                                Label
                                {
                                    id: chamberTemperatureLabel
                                    text: catalog.i18nc("@label", "Chamber temperature") + " (10-50°C)"
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item
                            {
                                id: chamberTemperatureCellRight

                                width: Math.round(base.width * .22)
                                height: chamberTemperatureCellLeft.height

                                anchors.left: chamberTemperatureCellLeft.right
                                anchors.bottom: chamberTemperatureCellLeft.bottom

                                TextField {
                                    width: parent.width
                                    height: UM.Theme.getSize("setting_control").height;
                                    property string unit: "°C";
                                    style: UM.Theme.styles.text_field;
                                    text: parseInt(UM.Preferences.getValue("custom_material/material_chamber_temperature"))
                                    anchors.verticalCenter: parent.verticalCenter
                                    validator: RegExpValidator { regExp: /^(?:[1-4][0-9]|50)$/ }
                                    maximumLength: 2
                                    onEditingFinished:
                                    {
                                        UM.Preferences.setValue("custom_material/material_chamber_temperature", parseInt(text))
                                    }
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: printSpeedRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: printSpeedCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .66)

                                Label
                                {
                                    id: printSpeedLabel
                                    text: catalog.i18nc("@label", "Speed")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item
                            {
                                id: printSpeedCellRight

                                width: Math.round(base.width * .25)
                                height: printSpeedCellLeft.height

                                anchors.left: printSpeedCellLeft.right
                                anchors.bottom: printSpeedCellLeft.bottom

                                ComboBox
                                {
                                    id: printSpeedCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbPSItems
                                        ListElement { text: "170%"; value: 1.7  }
                                        ListElement { text: "150%"; value: 1.5  }
                                        ListElement { text: "130%"; value: 1.3  }
                                        ListElement { text: "110%"; value: 1.1  }
                                        ListElement { text: "100%"; value: 1.0    }
                                        ListElement { text: "90%";  value: 0.9  }
                                        ListElement { text: "70%";  value: 0.7  }
                                        ListElement { text: "60%";  value: 0.6  }
                                        ListElement { text: "50%";  value: 0.5  }
                                        ListElement { text: "30%";  value: 0.3  }
                                    }

                                    currentIndex:
                                    {
                                        var val = UM.Preferences.getValue("custom_material/print_speed_multiplier")
                                        for(var i = 0; i < cbPSItems.count; ++i)
                                        {
                                            if(model.get(i).value == val)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: {
                                        var lastValue = UM.Preferences.getValue("custom_material/print_speed_multiplier")
                                        var value = model.get(index).value

                                        speedInfill.setPropertyValue("value", (speedInfill.properties.value / lastValue) * value)
                                        speedTopbottom.setPropertyValue("value", (speedTopbottom.properties.value / lastValue) * value)
                                        speedRoofing.setPropertyValue("value", (speedRoofing.properties.value / lastValue) * value)
                                        speedWall0.setPropertyValue("value", (speedWall0.properties.value / lastValue) * value)
                                        speedWallX.setPropertyValue("value", (speedWallX.properties.value / lastValue) * value)
                                        speedSupportRoof.setPropertyValue("value", (speedSupportRoof.properties.value / lastValue) * value)
                                        speedSupportInfill.setPropertyValue("value", (speedSupportInfill.properties.value / lastValue) * value)

                                        UM.Preferences.setValue("custom_material/print_speed_multiplier", model.get(index).value)
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
                            }
                        }
                    }

                    Item
                    {
                        id: materialFlowRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: materialFlowCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .66)

                                Label
                                {
                                    id: materialFlowLabel
                                    text: catalog.i18nc("@label", "Material flow")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item
                            {
                                id: materialFlowCellRight

                                width: Math.round(base.width * .25)
                                height: materialFlowCellLeft.height

                                anchors.left: materialFlowCellLeft.right
                                anchors.bottom: materialFlowCellLeft.bottom

                                ComboBox
                                {
                                    id: materialFlowCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbMFItems
                                        ListElement { text: "120%"; value: 120  }
                                        ListElement { text: "115%"; value: 115  }
                                        ListElement { text: "110%"; value: 110  }
                                        ListElement { text: "105%"; value: 105  }
                                        ListElement { text: "100%"; value: 100  }
                                        ListElement { text: "95%";  value:  95  }
                                        ListElement { text: "90%";  value:  90  }
                                        ListElement { text: "85%";  value:  85  }
                                        ListElement { text: "80%";  value:  80  }
                                        ListElement { text: "75%";  value:  75  }
                                        ListElement { text: "70%";  value:  70  }
                                        ListElement { text: "65%";  value:  65  }
                                        ListElement { text: "60%";  value:  60  }
                                        ListElement { text: "55%";  value:  55  }
                                        ListElement { text: "50%";  value:  50  }
                                        ListElement { text: "45%";  value:  45  }
                                        ListElement { text: "40%";  value:  40  }
                                    }

                                    currentIndex:
                                    {
                                        var val = UM.Preferences.getValue("custom_material/material_flow")
                                        for(var i = 0; i < cbMFItems.count; ++i)
                                        {
                                            if(model.get(i).value == val)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: {
                                        var value = model.get(index).value
                                        Cura.MachineManager.setSettingForAllExtruders("material_flow", "value", value)
                                        UM.Preferences.setValue("custom_material/material_flow", value)
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
                            }
                        }
                    }
                    Item
                    {
                        id: retractionSpeedRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: retractionSpeedCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .66)

                                Label
                                {
                                    id: retractionSpeedLabel
                                    text: catalog.i18nc("@label", "Retraction speed")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item
                            {
                                id: retractionSpeedCellRight

                                width: Math.round(base.width * .25)
                                height: retractionSpeedCellLeft.height

                                anchors.left: retractionSpeedCellLeft.right
                                anchors.bottom: retractionSpeedCellLeft.bottom

                                ComboBox
                                {
                                    id: retractionSpeedCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbRSItems
                                        ListElement { text: "5 mm/s" ; value: 5   }
                                        ListElement { text: "10 mm/s"; value: 10  }
                                        ListElement { text: "15 mm/s"; value: 15  }
                                        ListElement { text: "20 mm/s"; value: 20  }
                                        ListElement { text: "25 mm/s"; value: 250 }
                                    }

                                    currentIndex:
                                    {
                                        var val = parseInt(UM.Preferences.getValue("custom_material/retraction_speed"))
                                        for(var i = 0; i < cbRSItems.count; ++i)
                                        {
                                            if(model.get(i).value == val)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: {
                                        var value = model.get(index).value
                                        Cura.MachineManager.setSettingForAllExtruders("retraction_speed", "value", value)
                                        UM.Preferences.setValue("custom_material/retraction_speed", value)
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
                            }
                        }
                    }
                    Item
                    {
                        id: retractionLengthRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: retractionLengthCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .66)

                                Label
                                {
                                    id: retractionLengthLabel
                                    text: catalog.i18nc("@label", "Retraction amount")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Item
                            {
                                id: retractionLengthCellRight

                                width: Math.round(base.width * .25)
                                height: retractionLengthCellLeft.height

                                anchors.left: retractionLengthCellLeft.right
                                anchors.bottom: retractionLengthCellLeft.bottom

                                ComboBox
                                {
                                    id: retractionLengthCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbRLItems
                                        ListElement { text: "0 mm";   value: 0   }
                                        ListElement { text: "0.4 mm"; value: 0.4 }
                                        ListElement { text: "0.6 mm"; value: 0.6 }
                                        ListElement { text: "0.8 mm"; value: 0.8 }
                                        ListElement { text: "1 mm";   value: 1   }
                                        ListElement { text: "2 mm";   value: 2   }
                                        ListElement { text: "3 mm";   value: 3   }
                                    }

                                    currentIndex:
                                    {
                                        var val = parseFloat(UM.Preferences.getValue("custom_material/retraction_amount"))
                                        for(var i = 0; i < cbRLItems.count; ++i)
                                        {
                                            if(model.get(i).value == val)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: {
                                        var value = model.get(index).value
                                        Cura.MachineManager.setSettingForAllExtruders("retraction_enable", "value", value == 0 ? "False" : "True")
                                        Cura.MachineManager.setSettingForAllExtruders("retraction_amount", "value", value)
                                        UM.Preferences.setValue("custom_material/retraction_amount", value)
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
                            }
                        }
                    }
                    Button {
                        id: applyButton
                        style: UM.Theme.styles.sidebar_button
                        text: catalog.i18nc("@label", "OK")
                        Layout.rightMargin: UM.Theme.getSize("sidebar_margin").width * 2
                        Layout.topMargin: UM.Theme.getSize("sidebar_item_margin").height * 2
                        Layout.preferredWidth: 100
                        Layout.alignment: Qt.AlignRight
                        onClicked: {
                            prepareSidebar.switchView(0) // Default view
                        }
                    }
                }

                UM.SettingPropertyProvider
                {
                    id: speedInfill
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_infill"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedWall0
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_wall_0"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedWallX
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_wall_x"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedRoofing
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_roofing"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedTopbottom
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_topbottom"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedSupportRoof
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_support_roof"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedSupportInfill
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_support_infill"
                    watchedProperties: [ "value" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: supportEnabled
                    containerStack: Cura.MachineManager.activeMachine
                    key: "support_enable"
                    watchedProperties: [ "value", "enabled" ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: supportAngle
                    containerStack: Cura.MachineManager.activeMachine
                    key: "support_angle"
                    watchedProperties: [ "value", "enabled" ]
                    storeIndex: 0
                }
            }
        }
    }
}
