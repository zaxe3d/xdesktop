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

    property string lastSelectedMaterial: ""
    property bool customMaterialSelected: Cura.MachineManager.activeStack.material.name == "custom"
    property int cmpidx: parseInt(UM.Preferences.getValue("custom_material_profile/selected_index")) // custom material profile index

    function applyCustomMaterialSettings() {
        // apply custom settings here

        if (customMaterialSelected) {

            var valStr = "custom_material_profile/" + cmpidx + "_"
            Cura.MachineManager.setSettingForAllExtruders("material_print_temperature", "value", UM.Preferences.getValue(valStr + "material_print_temperature"))
        Cura.MachineManager.setSettingForAllExtruders("material_print_temperature_layer_0", "value", UM.Preferences.getValue(valStr + "material_print_temperature"))
            Cura.MachineManager.setSettingForAllExtruders("material_bed_temperature", "value", UM.Preferences.getValue(valStr + "material_bed_temperature"))
            Cura.MachineManager.setSettingForAllExtruders("material_bed_temperature_layer_0", "value", UM.Preferences.getValue(valStr + "material_bed_temperature"))

            // speed
            jerkPrint.setPropertyValue("value", UM.Preferences.getValue(valStr + "jerk_print"))
            accelerationPrint.setPropertyValue("value", UM.Preferences.getValue(valStr + "acceleration_print"))
            speedTravel.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_travel"))
            speedTopbottom.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_topbottom"))
            speedInfill.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_infill"))
            speedWall0.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_wall_0"))
            speedWallX.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_wall_x"))
            speedRoofing.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_roofing"))
            speedSupportRoof.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_support_roof"))
            speedSupportInfill.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_support_infill"))
            speedZHop.setPropertyValue("value", UM.Preferences.getValue(valStr + "speed_z_hop"))
            // end of speed
            Cura.MachineManager.setSettingForAllExtruders("wall_line_width_0", "value", UM.Preferences.getValue(valStr + "wall_line_width_0"))
            Cura.MachineManager.setSettingForAllExtruders("wall_line_width_x", "value", UM.Preferences.getValue(valStr + "wall_line_width_x"))
            Cura.MachineManager.setSettingForAllExtruders("support_line_width", "value", UM.Preferences.getValue(valStr + "support_line_width"))
            Cura.MachineManager.setSettingForAllExtruders("support_line_distance", "value", UM.Preferences.getValue(valStr + "support_line_distance"))
            Cura.MachineManager.setSettingForAllExtruders("support_interface_density", "value", UM.Preferences.getValue(valStr + "support_interface_density"))
            Cura.MachineManager.setSettingForAllExtruders("material_flow", "value", UM.Preferences.getValue(valStr + "material_flow"))
            Cura.MachineManager.setSettingForAllExtruders("retraction_speed", "value", UM.Preferences.getValue(valStr + "retraction_speed"))
            var retractionAmount = parseFloat(UM.Preferences.getValue(valStr + "retraction_amount"))
            Cura.MachineManager.setSettingForAllExtruders("retraction_enable", "value", retractionAmount == 0 ? "False" : "True")
            Cura.MachineManager.setSettingForAllExtruders("retraction_amount", "value", retractionAmount)
        } else if (["custom"].indexOf(lastSelectedMaterial) > -1) {
            Cura.ContainerManager.clearUserContainers();
            prepareSidebar.switchView(0) // Default view
            // set values coming from preferences back.
            supportEnabled.setPropertyValue("value", parseInt(UM.Preferences.getValue("slicing/support_angle")) > 0)
            supportAngle.setPropertyValue("value", (90 - Math.min(90, parseInt(UM.Preferences.getValue("slicing/support_angle")))))
            UM.Preferences.setValue("material/settings_applied", false)
        }

        lastSelectedMaterial = Cura.MachineManager.activeStack.material.name
    }

    onCustomMaterialSelectedChanged: applyCustomMaterialSettings()

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
                Layout.bottomMargin: 30

                ColumnLayout
                {
                    width: parent.parent.width

                    spacing: UM.Theme.getSize("sidebar_spacing").height

                    // Custom material profile selection
                    Item
                    {
                        id: customMaterialTitleRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: customMaterialTitleCellLeft

                                width: Math.round(base.width * .69)

                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    bottom: parent.bottom
                                }

                                Label
                                {
                                    id: customMaterialTitleLabel
                                    font: UM.Theme.getFont("large");
                                    text: catalog.i18nc("@label", "Custom material settings")

                                    anchors {
                                        top: parent.top
                                        topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Item
                            {
                                id: customMaterialTitleCellRight

                                width: Math.round(base.width * .22)
                                height: customMaterialTitleCellLeft.height

                                anchors {
                                    left: customMaterialTitleCellLeft.right
                                    bottom: customMaterialTitleCellLeft.bottom
                                }

                                ComboBox
                                {
                                    id: customMaterialProfilesCB
                                    width: parent.width
                                    height: UM.Theme.getSize("setting_control").height;
                                    anchors.verticalCenter: parent.verticalCenter
                                    editable: true
                                    focus: false

                                    Component.onCompleted: generateData()

                                    function generateData() {
                                        cMProfileModel.clear()
                                        for(var i = 0; i < 5; i++)
                                            cMProfileModel.append({ "description": UM.Preferences.getValue("custom_material_profile/" + i + "_name") })
                                        if (currentIndex != cmpidx)
                                            currentIndex = cmpidx // set the current index to previously selected one
                                    }

                                    model: ListModel { id: cMProfileModel }

                                    onAccepted: {
                                        if (find(editText) != -1) return// searching within existing items
                                        UM.Preferences.setValue("custom_material_profile/" + cmpidx + "_name", editText)
                                        focus = false
                                        generateData()
                                    }

                                    onCurrentIndexChanged: {
                                        if (currentIndex == -1 || !visible) return // editing the current one or with 0 when initializing.
                                        cmpidx = currentIndex
                                        UM.Preferences.setValue("custom_material_profile/selected_index", cmpidx)
                                        applyCustomMaterialSettings()
                                    }
                                }
                            }
                        }
                    }
                    Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2)
; Layout.preferredHeight: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark"); Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height }

                    Item
                    {
                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Label
                            {
                                font: UM.Theme.getFont("medium_bold");
                                text: catalog.i18nc("@label", "Temperature settings")

                                anchors {
                                    top: parent.top
                                    topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2)
; Layout.preferredHeight: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark"); Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Extruder temperature")
                        type: "int"
                        unit: "°C";
                        profileIdx: cmpidx
                        preferenceId: "material_print_temperature"
                        extraPreferenceId: "material_print_temperature_layer_0"
                        validator: IntValidator { bottom: 180; top: 300 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Bed temperature")
                        type: "int"
                        unit: "°C";
                        profileIdx: cmpidx
                        preferenceId: "material_bed_temperature"
                        validator: IntValidator { bottom: 50; top: 110 }
                    }

                    CustomMaterialSettingItem {
                        visible: Cura.MachineManager.activeMachineId != "X1" // X1 doesn't have chamber temp setting
                        label: catalog.i18nc("@label", "Chamber temperature") + " (10-60°C)"
                        type: "int"
                        unit: "°C";
                        profileIdx: cmpidx
                        preferenceId: "material_chamber_temperature"
                        validator: IntValidator { bottom: 10; top: 60 }
                    }

                    Item
                    {
                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Label
                            {
                                font: UM.Theme.getFont("medium_bold");
                                text: catalog.i18nc("@label", "Extrusion width settings")

                                anchors {
                                    top: parent.top
                                    topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2)
; Layout.preferredHeight: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark"); Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "First wall (0) line width")
                        type: "float"
                        unit: "mm";
                        profileIdx: cmpidx
                        preferenceId: "wall_line_width_0"
                        validator: DoubleValidator { bottom: 0.2; top: 1; decimals: 2 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Other wall(s) (X) line width")
                        type: "float"
                        unit: "mm";
                        profileIdx: cmpidx
                        preferenceId: "wall_line_width_x"
                        validator: DoubleValidator { bottom: 0.2; top: 1; decimals: 2}
                    }

                    Item
                    {
                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Label
                            {
                                font: UM.Theme.getFont("medium_bold");
                                text: catalog.i18nc("@label", "Support settings")

                                anchors {
                                    top: parent.top
                                    topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2)
; Layout.preferredHeight: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark"); Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Support line width")
                        type: "float"
                        unit: "mm";
                        profileIdx: cmpidx
                        preferenceId: "support_line_width"
                        validator: DoubleValidator { bottom: 0.2; top: 1; decimals: 2}
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Support line distance")
                        type: "float"
                        unit: "mm";
                        profileIdx: cmpidx
                        preferenceId: "support_line_distance"
                        validator: DoubleValidator { bottom: 0; top: 5; decimals: 2}
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Support interface density")
                        type: "int"
                        unit: "%";
                        profileIdx: cmpidx
                        preferenceId: "support_interface_density"
                        validator: IntValidator { bottom: 0; top: 100 }
                    }

                    Item
                    {
                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Label
                            {
                                font: UM.Theme.getFont("medium_bold");
                                text: catalog.i18nc("@label", "Speed settings")

                                anchors {
                                    top: parent.top
                                    topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2)
; Layout.preferredHeight: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark"); Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Print acceleration")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "acceleration_print"
                        validator: IntValidator { bottom: 100; top: 10000 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Print jerk")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "jerk_print"
                        validator: IntValidator { bottom: 0; top: 50 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Travel speed")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_travel"
                        validator: IntValidator { bottom: 1; top: 300 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Speed top/bottom")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_topbottom"
                        validator: IntValidator { bottom: 1; top: 150 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Speed infill")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_infill"
                        validator: IntValidator { bottom: 1; top: 150 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "First wall (0) speed")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_wall_0"
                        validator: IntValidator { bottom: 1; top: 150 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Other wall(s) (X) speed(s)")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_wall_x"
                        validator: IntValidator { bottom: 1; top: 150 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Roofing speed")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_roofing"
                        validator: IntValidator { bottom: 1; top: 150 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Support roofing speed")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_support_roof"
                        validator: IntValidator { bottom: 1; top: 150 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Support infill speed")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_support_infill"
                        validator: IntValidator { bottom: 1; top: 150 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Retraction speed")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "retraction_speed"
                        validator: IntValidator { bottom: 1; top: 40}
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Z hop speed")
                        type: "int"
                        unit: "mm/s";
                        profileIdx: cmpidx
                        preferenceId: "speed_z_hop"
                        validator: IntValidator { bottom: 0; top: 100 }
                    }

                    Item
                    {
                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Label
                            {
                                font: UM.Theme.getFont("medium_bold");
                                text: catalog.i18nc("@label", "Other settings")

                                anchors {
                                    top: parent.top
                                    topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2)
; Layout.preferredHeight: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark"); Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Material flow")
                        type: "int"
                        unit: "%";
                        profileIdx: cmpidx
                        preferenceId: "material_flow"
                        validator: IntValidator { bottom: 40; top: 120 }
                    }

                    CustomMaterialSettingItem {
                        label: catalog.i18nc("@label", "Retraction amount")
                        type: "float"
                        unit: "mm";
                        profileIdx: cmpidx
                        preferenceId: "retraction_amount"
                        validator: DoubleValidator { bottom: 0; top: 10 }
                        extraFunc: function() {
                            Cura.MachineManager.setSettingForAllExtruders("retraction_enable", "value", parseFloat(UM.Preferences.getValue(valStr)) == 0 ? "False" : "True")
                        }
                    }

                    Button {
                        id: applyButton
                        style: UM.Theme.styles.sidebar_button
                        text: catalog.i18nc("@label", "OK")
                        Layout.rightMargin: UM.Theme.getSize("sidebar_margin").width * 2
                        Layout.topMargin: UM.Theme.getSize("sidebar_item_margin").height * 2
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 30
                        Layout.alignment: Qt.AlignRight
                        onClicked: {
                            prepareSidebar.switchView(0) // Default view
                            CuraApplication.saveSettings()
                        }
                    }
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
                UM.SettingPropertyProvider
                {
                    id: speedInfill
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_infill"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedWall0
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_wall_0"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0
                }
                UM.SettingPropertyProvider
                {
                    id: speedWallX
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_wall_x"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: speedRoofing
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_roofing"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: speedTopbottom
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_topbottom"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: jerkPrint
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "jerk_print"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: accelerationPrint
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "acceleration_print"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: speedTravel
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_travel"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: speedZHop
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_z_hop"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: speedSupportRoof
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_support_roof"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
                UM.SettingPropertyProvider
                {
                    id: speedSupportInfill
                    containerStackId: Cura.MachineManager.activeMachineId
                    key: "speed_support_infill"
                    watchedProperties: [ "value"  ]
                    storeIndex: 0

                }
            }
        }
    }
}
