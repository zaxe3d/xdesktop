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

    signal showFirstrunTip(point position, string title, string text, bool nextAvailable, bool imgPath)

    property int backendState: UM.Backend.state
    property int  supportAngle: UM.Preferences.getValue("slicing/support_angle")
    property bool supportEnabled: UM.Preferences.getValue("slicing/support_angle") > 0

    UM.I18nCatalog { id: catalog; name: "cura" }

    function booleanToString(bool) {
        return bool ? "True" : "False";
    }

    Connections {
        target: UM.Preferences
        onPreferenceChanged:
        {
            base.supportAngle = UM.Preferences.getValue("slicing/support_angle")
            base.supportEnabled = UM.Preferences.getValue("slicing/support_angle") > 0
        }
    }

    ScrollView
    {
        visible: Cura.MachineManager.activeMachineName != "" // If no printers added then the view is invisible
        anchors.fill: parent
        style: UM.Theme.styles.scrollview
        flickableItem.flickableDirection: Flickable.VerticalFlick

        ColumnLayout
        {
            width: parent.parent.width
            anchors.top: parent.top
            spacing: UM.Theme.getSize("sidebar_spacing").height

            //
            // Quality profile
            //
            Item
            {
                id: qualityRow

                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 120
                Layout.alignment: Qt.AlignLeft

                Timer
                {
                    id: qualitySliderChangeTimer
                    interval: 50
                    running: false
                    repeat: false
                    onTriggered:
                    {
                        var item = Cura.QualityProfilesDropDownMenuModel.getItem(qualitySlider.value);
                        Cura.MachineManager.activeQualityGroup = item.quality_group;
                    }
                }

                Component.onCompleted: qualityModel.update()

                Connections
                {
                    target: Cura.QualityProfilesDropDownMenuModel
                    onItemsChanged: qualityModel.update()
                }

                Connections {
                    target: base
                    onVisibleChanged:
                    {
                        // update needs to be called when the widgets are visible, otherwise the step width calculation
                        // will fail because the width of an invisible item is 0.
                        if (visible)
                        {
                            qualityModel.update();
                        }
                    }
                }

                ListModel
                {
                    id: qualityModel

                    property var totalTicks: 0
                    property var availableTotalTicks: 0
                    property var existingQualityProfile: 0

                    property var qualitySliderActiveIndex: 0
                    property var qualitySliderStepWidth: 0
                    property var qualitySliderAvailableMin: 0
                    property var qualitySliderAvailableMax: 0
                    property var qualitySliderMarginRight: 0

                    function update ()
                    {
                        reset()

                        var availableMin = -1
                        var availableMax = -1

                        for (var i = 0; i < Cura.QualityProfilesDropDownMenuModel.rowCount(); i++)
                        {
                            var qualityItem = Cura.QualityProfilesDropDownMenuModel.getItem(i)

                            // Add each quality item to the UI quality model
                            qualityModel.append(qualityItem)

                            // Set selected value
                            if (Cura.MachineManager.activeQualityType == qualityItem.quality_type)
                            {
                                // set to -1 when switching to user created profile so all ticks are clickable
                                qualityModel.qualitySliderActiveIndex = i
                                qualityModel.existingQualityProfile = 1
                            }

                            // Set min available
                            if (qualityItem.available && availableMin == -1)
                            {
                                availableMin = i
                            }

                            // Set max available
                            if (qualityItem.available)
                            {
                                availableMax = i
                            }
                        }

                        // Set total available ticks for active slider part
                        if (availableMin != -1)
                        {
                            qualityModel.availableTotalTicks = availableMax - availableMin + 1
                        }

                        // Calculate slider values
                        calculateSliderStepWidth(qualityModel.totalTicks)
                        calculateSliderMargins(availableMin, availableMax, qualityModel.totalTicks)

                        qualityModel.qualitySliderAvailableMin = availableMin
                        qualityModel.qualitySliderAvailableMax = availableMax
                    }

                    function calculateSliderStepWidth (totalTicks)
                    {
                        qualityModel.qualitySliderStepWidth = totalTicks != 0 ? Math.round((base.width * 0.55) / (totalTicks)) : 0
                    }

                    function calculateSliderMargins (availableMin, availableMax, totalTicks)
                    {
                        if (availableMin == -1 || (availableMin == 0 && availableMax == 0))
                        {
                            qualityModel.qualitySliderMarginRight = Math.round(base.width * 0.55)
                        }
                        else if (availableMin == availableMax)
                        {
                            qualityModel.qualitySliderMarginRight = Math.round((totalTicks - availableMin) * qualitySliderStepWidth)
                        }
                        else
                        {
                            qualityModel.qualitySliderMarginRight = Math.round((totalTicks - availableMax) * qualitySliderStepWidth)
                        }
                    }

                    function reset () {
                        qualityModel.clear()
                        qualityModel.availableTotalTicks = 0
                        qualityModel.existingQualityProfile = 0

                        // check, the ticks count cannot be less than zero
                        qualityModel.totalTicks = Math.max(0, Cura.QualityProfilesDropDownMenuModel.rowCount() - 1)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: UM.Theme.getColor("sidebar_item_light")
                    width: parent.width
                    Item
                    {
                        id: qualityCellLeft

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom

                        width: Math.round(base.width * .27)

                        Label
                        {
                            id: qualityLabel
                            text: catalog.i18nc("@label", "Layer height")
                            font: UM.Theme.getFont("large_semi_bold");
                            color: UM.Theme.getColor("text_sidebar");

                            anchors.top: parent.top
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height + UM.Theme.getSize("default_lining").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                        }
                        Image
                        {
                            width: 11; height: 12

                            source: UM.Theme.getImage("info")

                            anchors { left: qualityLabel.right; verticalCenter: qualityLabel.verticalCenter; leftMargin: 5 }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                {
                                    UM.Preferences.setValue("cura/help_page", 0)
                                    UM.Controller.setActiveStage("Help")
                                }
                            }
                        }
                        Rectangle
                        {
                            id: qualityIcon

                            width: 70; height: width
                            radius: 5

                            anchors.top: qualityLabel.bottom
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_icon_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_icon_margin").width

                            Rectangle
                            {
                                anchors.fill: parent
                                radius: 5
                                color: UM.Theme.getColor("slider_groove")

                                Image {
                                    antialiasing: true
                                    anchors.fill: parent
                                    source: "../../plugins/NetworkMachineList/resources/images/layer_height/" + parseInt(qualitySlider.value) + ".png"
                                    sourceSize.width: width
                                    sourceSize.height: width
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: qualityCellRight

                        width: Math.round(base.width * .60)
                        height: qualityCellLeft.height

                        anchors.left: qualityCellLeft.right
                        anchors.bottom: qualityCellLeft.bottom
                        anchors.bottomMargin: 8

                        Label
                        {
                            id: selectedQualityText

                            anchors.bottom: parent.bottom
                            anchors.left: qualitySlider.left
                            anchors.leftMargin: Math.round(((qualitySlider.value - qualitySlider.minimumValue) / qualitySlider.stepSize) * (qualitySlider.width
                                                / ((qualitySlider.maximumValue - qualitySlider.minimumValue) / qualitySlider.stepSize)) - 10 * screenScaleFactor)
                            anchors.right: parent.right

                            font: UM.Theme.getFont("large_nonbold")

                            text: Cura.QualityProfilesDropDownMenuModel.getItem(qualitySlider.value).layer_height + " mm"

                            color: UM.Theme.getColor("text_sidebar_medium")
                        }

                        Slider
                        {
                            id: qualitySlider

                            anchors.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height / 2
                            anchors.bottom: selectedQualityText.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: UM.Theme.getSize("sidebar_margin").height
                            //width: parseInt(qualityCellRight.width - UM.Theme.getSize("sidebar_margin").width - style.handleWidth)

                            enabled: qualityModel.totalTicks > 0
                            visible: qualityModel.availableTotalTicks > 0
                            updateValueWhileDragging : true

                            minimumValue: qualityModel.qualitySliderAvailableMin >= 0 ? qualityModel.qualitySliderAvailableMin : 0
                            // maximumValue must be greater than minimumValue to be able to see the handle. While the value is strictly
                            // speaking not always correct, it seems to have the correct behavior (switching from 0 available to 1 available)
                            maximumValue: qualityModel.qualitySliderAvailableMax >= 1 ? qualityModel.qualitySliderAvailableMax : 1
                            stepSize: 1

                            value: qualityModel.qualitySliderActiveIndex

                            width: qualityModel.qualitySliderStepWidth * (qualityModel.availableTotalTicks - 1)

                            anchors.rightMargin: qualityModel.qualitySliderMarginRight

                            onValueChanged:
                            {
                                // only change if an active machine is set and the slider is visible at all.
                                if (Cura.MachineManager.activeMachine != null && visible)
                                {
                                    // prevent updating during view initializing. Trigger only if the value changed by user
                                    if (qualitySlider.value != qualityModel.qualitySliderActiveIndex && qualityModel.qualitySliderActiveIndex != -1)
                                    {
                                        // start updating with short delay
                                        qualitySliderChangeTimer.start()
                                    }
                                }
                            }

                            style: SliderStyle
                            {
                                groove: Rectangle {
                                    id: groove
                                    implicitWidth: 200 * screenScaleFactor
                                    implicitHeight: 15 * screenScaleFactor
                                    color: control.enabled ? UM.Theme.getColor("slider_groove") : UM.Theme.getColor("quality_slider_unavailable")
                                    radius: 5
                                }

                                handle: Item {
                                    Rectangle {
                                        id: handleButton
                                        anchors.centerIn: parent
                                        color: control.enabled ? UM.Theme.getColor("slider_handle") : UM.Theme.getColor("quality_slider_unavailable")
                                        implicitWidth: 23 * screenScaleFactor
                                        implicitHeight: 23 * screenScaleFactor
                                        radius: 100
                                    }
                                }
                            }

                            Component.onCompleted: {
                                for (var i = 0; i < qualitySlider.children.length; ++i) {
                                    if (qualitySlider.children[i].hasOwnProperty("onVerticalWheelMoved") && qualitySlider.children[i].hasOwnProperty("onHorizontalWheelMoved")) {
                                        qualitySlider.children[i].destroy()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Bottom Border
            Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2); Layout.alignment: Qt.AlignHCenter; height: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

            //
            // Support angle
            //
            Item
            {
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 120
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    anchors.fill: parent
                    color: UM.Theme.getColor("sidebar_item_light")
                    width: parent.width
                    Item
                    {
                        id: supportAngleCellLeft

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom

                        width: Math.round(base.width * .27)

                        Label
                        {
                            id: supportLabel
                            text: catalog.i18nc("@label", "Support")
                            font: UM.Theme.getFont("large_semi_bold");
                            color: UM.Theme.getColor("text_sidebar")

                            anchors.top: parent.top
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                        }
                        Image
                        {
                            id: supportHelp
                            width: 11; height: 12

                            source: UM.Theme.getImage("info")

                            anchors { left: supportLabel.right; verticalCenter: supportLabel.verticalCenter; leftMargin: 5 }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                {
                                    UM.Preferences.setValue("cura/help_page", 1)
                                    UM.Controller.setActiveStage("Help")
                                }
                            }
                        }
                        ComboBox
                        {
                            id: supportExtruderCombobox
                            visible: supportEnabled.properties.value == "True" && extrudersEnabledCount.properties.value > 1
                            model: extruderModel
                            anchors.verticalCenter: supportHelp.verticalCenter
                            anchors.left: supportHelp.right

                            property string color_override: ""  // for manually setting values
                            property string color:  // is evaluated automatically, but the first time is before extruderModel being filled
                            {
                                var current_extruder = extruderModel.get(currentIndex);
                                color_override = "";
                                if (current_extruder === undefined) return ""
                                return (current_extruder.color) ? current_extruder.color : "";
                            }

                            textRole: "text"  // this solves that the combobox isn't populated in the first time Cura is started

                            anchors.leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2)

                            width: 125
                            height: UM.Theme.getSize("setting_control").height

                            Behavior on height { NumberAnimation { duration: 100 } }

                            style: UM.Theme.styles.combobox_color

                            currentIndex:
                            {
                                if (supportExtruderNr.properties == null)
                                {
                                    return Cura.MachineManager.defaultExtruderPosition;
                                }
                                else
                                {
                                    var extruder = parseInt(supportExtruderNr.properties.value);
                                    if (extruder === -1)
                                    {
                                        return Cura.MachineManager.defaultExtruderPosition;
                                    }
                                    return extruder;
                                }
                            }

                            onActivated:
                            {
                                // Send the extruder nr as a string.
                                supportExtruderNr.setPropertyValue("value", String(index));
                            }

                            function updateCurrentColor()
                            {
                                var current_extruder = extruderModel.get(currentIndex);
                                if (current_extruder !== undefined) {
                                    supportExtruderCombobox.color_override = current_extruder.color;
                                }
                            }
                        }
                        Rectangle
                        {
                            id: supportAngleIcon

                            width: 70; height: width
                            radius: 5

                            anchors.top: supportLabel.bottom
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_icon_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_icon_margin").width

                            Rectangle
                            {
                                anchors.fill: parent

                                color: UM.Theme.getColor("slider_groove")
                                radius: 5

                                Image {
                                    antialiasing: true
                                    anchors.fill: parent
                                    source: "../../plugins/NetworkMachineList/resources/images/support_angle/" + base.supportAngle + ".png"
                                    sourceSize.width: width
                                    sourceSize.height: width
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: supportAngleCellRight

                        width: Math.round(base.width * .60)
                        height: supportAngleCellLeft.height

                        anchors.left: supportAngleCellLeft.right
                        anchors.bottom: supportAngleCellLeft.bottom
                        anchors.bottomMargin: 12

                        Label
                        {
                            id: selectedsupportAngleRateText

                            anchors.bottom: parent.bottom
                            anchors.left: supportAngleSlider.left
                            anchors.leftMargin: Math.round((supportAngleSlider.value / supportAngleSlider.stepSize) * (supportAngleSlider.width / (supportAngleSlider.maximumValue / supportAngleSlider.stepSize)) - 10 * screenScaleFactor)
                            anchors.right: parent.right

                            font: UM.Theme.getFont("large_nonbold")

                            text: base.supportEnabled ? base.supportAngle + "°" : catalog.i18nc("@label", "Support off")

                            color: UM.Theme.getColor("text_sidebar_medium")
                        }

                        // We use a binding to make sure that after manually setting supportAngleSlider.value it is still bound to the property provider
                        Binding {
                            target: supportAngleSlider
                            property: "value"
                            value: UM.Preferences.getValue("slicing/support_angle")
                        }

                        Slider
                        {
                            id: supportAngleSlider

                            anchors.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height / 2
                            anchors.bottom: selectedsupportAngleRateText.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: UM.Theme.getSize("sidebar_margin").height
                            width: parseInt(supportAngleCellRight.width - UM.Theme.getSize("sidebar_margin").width - style.handleWidth)

                            minimumValue: 0
                            maximumValue: 50
                            stepSize: 10
                            tickmarksEnabled: false

                            // set initial value
                            value: UM.Preferences.getValue("slicing/support_angle")

                            onValueChanged: {


                                var angle = parseInt(supportAngleSlider.value)
                                var prefAngle = parseInt(UM.Preferences.getValue("slicing/support_angle"))

                                if (angle > 0) {
                                    supportEnabled.setPropertyValue("value", true)
                                    supportSkipSomeZags.setPropertyValue("value", false)
                                } else {
                                    supportEnabled.setPropertyValue("value", false)
                                }


                                // only set if different
                                if (prefAngle != angle) {
                                    UM.Preferences.setValue("slicing/support_angle", angle)
                                }


                                supportAngle.setPropertyValue("value", (90 - Math.min(90, angle)))
                            }

                            style: SliderStyle
                            {
                                groove: Rectangle {
                                    id: groove
                                    implicitWidth: 200 * screenScaleFactor
                                    implicitHeight: 15 * screenScaleFactor
                                    color: control.enabled ? UM.Theme.getColor("slider_groove") : UM.Theme.getColor("quality_slider_unavailable")
                                    radius: 5
                                }

                                handle: Item {
                                    Rectangle {
                                        id: handleButton
                                        anchors.centerIn: parent
                                        color: control.enabled ? UM.Theme.getColor("slider_handle") : UM.Theme.getColor("quality_slider_unavailable")
                                        implicitWidth: 23 * screenScaleFactor
                                        implicitHeight: 23 * screenScaleFactor
                                        radius: 100
                                    }
                                }
                            }
                            Component.onCompleted: {
                                for (var i = 0; i < supportAngleSlider.children.length; ++i) {
                                    if (supportAngleSlider.children[i].hasOwnProperty("onVerticalWheelMoved") && supportAngleSlider.children[i].hasOwnProperty("onHorizontalWheelMoved")) {
                                        supportAngleSlider.children[i].destroy()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //
            // Raft
            //
            Item
            {
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 70
                Layout.bottomMargin: 15
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    anchors.fill: parent
                    color: UM.Theme.getColor("sidebar_item_light")
                    width: parent.width
                    Rectangle
                    {
                        id: raftCellLeft

                        color: UM.Theme.getColor("sidebar_item_light")
                        width: Math.round(base.width * .27)
                        height: 90

                        radius: 5

                        anchors.left: parent.left

                        Rectangle
                        {
                            id: raftIcon

                            width: 70; height: width
                            radius: 5

                            anchors.top: parent.top
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_icon_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_icon_margin").width

                            color: UM.Theme.getColor("slider_groove")

                            Image {
                                antialiasing: true
                                anchors.fill: parent
                                source: "../../plugins/NetworkMachineList/resources/images/raft/" +
                                    (platformAdhesionType.properties.value == "none" ? "off" : "on") + ".png"
                                sourceSize.width: width
                                sourceSize.height: width
                            }
                        }
                    }

                    Item
                    {
                        id: raftCellRight

                        width: Math.round(base.width * .60)
                        height: raftCellLeft.height

                        anchors.left: raftCellLeft.right
                        anchors.bottom: raftCellLeft.bottom

                        CheckBox
                        {
                            id: adhesionCheckBox
                            property alias _hovered: adhesionMouseArea.containsMouse
                            property bool checkBoxSidebar: true

                            anchors.top: parent.top
                            anchors.left: raftCellRight.left
                            anchors.verticalCenter: parent.verticalCenter

                            //: Setting enable printing build-plate adhesion helper checkbox
                            style: UM.Theme.styles.checkbox;

                            visible: platformAdhesionType.properties.enabled == "True"
                            checked: platformAdhesionType.properties.value != "none"
                            text: catalog.i18nc("@label", "Raft")

                            MouseArea
                            {
                                id: adhesionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:
                                {
                                    parent.checked = !parent.checked;
                                    var adhesionType = parent.checked ? "raft" : "none";
                                    platformAdhesionType.setPropertyValue("value", adhesionType);
                                }
                            }
                        }
                        Image
                        {
                            width: 11; height: 12

                            source: UM.Theme.getImage("info")

                            anchors { left: adhesionCheckBox.right; verticalCenter: adhesionCheckBox.verticalCenter; leftMargin: 5 }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                {
                                    UM.Preferences.setValue("cura/help_page", 2)
                                    UM.Controller.setActiveStage("Help")
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Border
            Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2); Layout.alignment: Qt.AlignHCenter; height: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

            //
            // Infill
            //
            Item
            {
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 120
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    anchors.fill: parent
                    color: UM.Theme.getColor("sidebar_item_light")
                    width: parent.width
                    Item
                    {
                        id: infillCellLeft

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom

                        width: Math.round(base.width * .27)

                        Label
                        {
                            id: infillLabel
                            text: catalog.i18nc("@label", "Fill density")
                            font: UM.Theme.getFont("large");
                            color: UM.Theme.getColor("text_sidebar")

                            anchors.top: parent.top
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                        }
                        Image
                        {
                            width: 11; height: 12

                            source: UM.Theme.getImage("info")

                            anchors { left: infillLabel.right; verticalCenter: infillLabel.verticalCenter; leftMargin: 5 }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onClicked:
                                {
                                    UM.Preferences.setValue("cura/help_page", 3)
                                    UM.Controller.setActiveStage("Help")
                                }
                            }
                        }
                        Rectangle
                        {
                            id: infillIcon

                            width: 70; height: width
                            radius: 5

                            anchors.top: infillLabel.bottom
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_icon_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_icon_margin").width

                            Rectangle
                            {
                                anchors.fill: parent

                                radius: 5

                                Image {
                                    antialiasing: true
                                    anchors.fill: parent
                                    source: "../../plugins/NetworkMachineList/resources/images/infill/" + parseInt(infillDensity.properties.value) + ".png"
                                    sourceSize.width: width
                                    sourceSize.height: width
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: infillCellRight

                        width: Math.round(base.width * .60)
                        height: infillCellLeft.height

                        anchors.left: infillCellLeft.right
                        anchors.bottom: infillCellLeft.bottom
                        anchors.bottomMargin: 12

                        Label
                        {
                            id: selectedInfillRateText

                            anchors.bottom: parent.bottom
                            anchors.left: infillSlider.left
                            anchors.leftMargin: Math.round((infillSlider.value / infillSlider.stepSize) * (infillSlider.width / (infillSlider.maximumValue / infillSlider.stepSize)) - 10 * screenScaleFactor)
                            anchors.right: parent.right

                            font: UM.Theme.getFont("large_nonbold")

                            text: "%" + parseInt(infillDensity.properties.value)

                            color: UM.Theme.getColor("text_sidebar_medium")
                        }

                        // We use a binding to make sure that after manually setting infillSlider.value it is still bound to the property provider
                        Binding {
                            target: infillSlider
                            property: "value"
                            value: parseInt(infillDensity.properties.value)
                        }

                        Slider
                        {
                            id: infillSlider

                            anchors.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height / 2
                            anchors.bottom: selectedInfillRateText.top
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height: UM.Theme.getSize("sidebar_margin").height
                            width: parseInt(infillCellRight.width - UM.Theme.getSize("sidebar_margin").width - style.handleWidth)

                            minimumValue: 0
                            maximumValue: 100
                            stepSize: 1
                            tickmarksEnabled: false

                            // disable slider when gradual support is enabled
                            enabled: parseInt(infillSteps.properties.value) == 0

                            // set initial value from stack
                            value: parseInt(infillDensity.properties.value)

                            onValueChanged: {

                                // Don't round the value if it's already the same
                                if (parseInt(infillDensity.properties.value) == infillSlider.value) {
                                    return
                                }

                                var roundedSliderValue = 0
                                // Round the slider value to the nearest multiple of 10 (simulate step size of 10)
                                if (infillSlider.value <= 5) // to enable 1 to 5
                                    roundedSliderValue = infillSlider.value
                                else
                                    roundedSliderValue = Math.round(infillSlider.value / 10) * 10

                                // Update the slider value to represent the rounded value
                                infillSlider.value = roundedSliderValue

                                Cura.MachineManager.setSettingForAllExtruders("infill_sparse_density", "value", roundedSliderValue)
                            }

                            style: SliderStyle
                            {
                                groove: Rectangle {
                                    id: groove
                                    implicitWidth: 200 * screenScaleFactor
                                    implicitHeight: 15 * screenScaleFactor
                                    color: control.enabled ? UM.Theme.getColor("slider_groove") : UM.Theme.getColor("quality_slider_unavailable")
                                    radius: 5
                                }

                                handle: Item {
                                    Rectangle {
                                        id: handleButton
                                        anchors.centerIn: parent
                                        color: control.enabled ? UM.Theme.getColor("slider_handle") : UM.Theme.getColor("quality_slider_unavailable")
                                        implicitWidth: 23 * screenScaleFactor
                                        implicitHeight: 23 * screenScaleFactor
                                        radius: 100
                                    }
                                }
                            }
                            Component.onCompleted: {
                                // Disable mouse wheel on old sliders.
                                for (var i = 0; i < infillSlider.children.length; ++i) {
                                    if (infillSlider.children[i].hasOwnProperty("onVerticalWheelMoved") && infillSlider.children[i].hasOwnProperty("onHorizontalWheelMoved")) {
                                        infillSlider.children[i].destroy()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Bottom Border
            Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2); Layout.alignment: Qt.AlignHCenter; height: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

            //
            // Advanced settings
            //
            Item
            {
                id: advancedSettingsPane
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: childrenRect.height
                Layout.alignment: Qt.AlignLeft
                Layout.topMargin: UM.Theme.getSize("sidebar_margin").height
                visible: false

                ColumnLayout
                {
                    width: parent.parent.width
                    spacing: UM.Theme.getSize("sidebar_spacing").height

                    Item
                    {
                        id: zSeamTypeRow

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
                                id: zSeamTypeCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: zSeamTypeLabel
                                    text: catalog.i18nc("@label", "Seam type")
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
                                id: zSeamTypeCellRight

                                width: Math.round(base.width * .38)
                                height: zSeamTypeCellLeft.height

                                anchors.left: zSeamTypeCellLeft.right
                                anchors.bottom: zSeamTypeCellLeft.bottom

                                ComboBox
                                {
                                    id: zSeamTypeCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: [
                                        { text: catalog.i18nc("@item:inlistbox", "Back"),                value: "back"           },
                                        { text: catalog.i18nc("@item:inlistbox", "Shortest"),            value: "shortest"       },
                                        { text: catalog.i18nc("@item:inlistbox", "Random"),              value: "random"         },
                                        { text: catalog.i18nc("@item:inlistbox", "Sharpest Corner"),     value: "sharpest_corner"}
                                    ]

                                    currentIndex:
                                    {
                                        var iP = zSeamType.properties.value
                                        for(var i = 0; i < model.length; i++)
                                        {
                                            if(model[i].value == iP)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: zSeamType.setPropertyValue("value", model[index].value)

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
                        id: zSeamCornerRow

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
                                id: zSeamCornerCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: zSeamCornerLabel
                                    text: catalog.i18nc("@label", "Seam Corner")
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
                                id: zSeamCornerCellRight

                                width: Math.round(base.width * .38)
                                height: zSeamCornerCellLeft.height

                                anchors.left: zSeamCornerCellLeft.right
                                anchors.bottom: zSeamCornerCellLeft.bottom

                                ComboBox
                                {
                                    id: zSeamCornerCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: [
                                        { text: catalog.i18nc("@item:inlistbox", "None"),                value: "z_seam_corner_none" },
                                        { text: catalog.i18nc("@item:inlistbox", "Hide Seam"),           value: "z_seam_corner_inner" },
                                        { text: catalog.i18nc("@item:inlistbox", "Expose Seam"),         value: "z_seam_corner_outer" },
                                        { text: catalog.i18nc("@item:inlistbox", "Hide or Expose Seam"), value: "z_seam_corner_any" },
                                        { text: catalog.i18nc("@item:inlistbox", "Smart Hiding"),        value: "z_seam_corner_weighted" }
                                    ]

                                    currentIndex:
                                    {
                                        var iP = zSeamCorner.properties.value
                                        for(var i = 0; i < model.length; i++)
                                        {
                                            if(model[i].value == iP)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: zSeamCorner.setPropertyValue("value", model[index].value)

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
                        id: adhesionTypeRow

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
                                id: adhesionTypeCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: adhesionTypeLabel
                                    text: catalog.i18nc("@label", "Adhesion type")
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
                                id: adhesionTypeCellRight

                                width: Math.round(base.width * .38)
                                height: adhesionTypeCellLeft.height

                                anchors.left: adhesionTypeCellLeft.right
                                anchors.bottom: adhesionTypeCellLeft.bottom

                                ComboBox
                                {
                                    id: adhesionTypeCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: [
                                        { text: catalog.i18nc("@item:inlistbox", "Off"),         value: "none"   },
                                        { text: catalog.i18nc("@item:inlistbox", "Raft"),        value: "raft"   },
                                        { text: catalog.i18nc("@item:inlistbox", "Brim"),        value: "brim"   },
                                        { text: catalog.i18nc("@item:inlistbox", "Skirt"),       value: "skirt"   },
                                    ]

                                    currentIndex:
                                    {
                                        var iP = platformAdhesionType.properties.value
                                        for(var i = 0; i < model.length; i++)
                                        {
                                            if(model[i].value == iP)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: platformAdhesionType.setPropertyValue("value", model[index].value)

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
                        id: infillPatternRow

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
                                id: infillPatternCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: infillPatternLabel
                                    text: catalog.i18nc("@label", "Infill pattern")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: infillPatternLabel.right; verticalCenter: infillPatternLabel.verticalCenter; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 3)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                id: infillPatternCellRight

                                width: Math.round(base.width * .38)
                                height: infillPatternCellLeft.height

                                anchors.left: infillPatternCellLeft.right
                                anchors.bottom: infillPatternCellLeft.bottom

                                ComboBox
                                {
                                    id: infillPatternCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbIPItems
                                        ListElement { text: "Grid";                   value: "grid"           }
                                        ListElement { text: "Lines";                  value: "lines"          }
                                        ListElement { text: "Triangles";              value: "triangles"      }
                                        ListElement { text: "Tri-Hexagon";            value: "trihexagon"     }
                                        ListElement { text: "Cubic";                  value: "cubic"          }
                                        ListElement { text: "Cubic Subdivision";      value: "cubicsubdiv"    }
                                        ListElement { text: "Octet";                  value: "tetrahedral"    }
                                        ListElement { text: "Quarter Cubic";          value: "quarter_cubic"  }
                                        ListElement { text: "Concentric";             value: "concentric"     }
                                        ListElement { text: "Zig Zag";                value: "zigzag"         }
                                        ListElement { text: "Cross";                  value: "cross"          }
                                        ListElement { text: "Cross 3D";               value: "cross_3d"       }
                                        ListElement { text: "Gyroid";                 value: "gyroid"         }
                                    }

                                    currentIndex:
                                    {
                                        var iP = infillPattern.properties.value
                                        for(var i = 0; i < cbIPItems.count; ++i)
                                        {
                                            if(model.get(i).value == iP)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: infillPattern.setPropertyValue("value", model.get(index).value)

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
                        id: perimeterCountRow

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
                                id: perimeterCountCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: perimeterCountLabel
                                    text: catalog.i18nc("@label", "Perimeter count")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: perimeterCountLabel.right; verticalCenter: perimeterCountLabel.verticalCenter; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 4)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                id: perimeterCountCellRight

                                width: Math.round(base.width * .38)
                                height: perimeterCountCellLeft.height

                                anchors.left: perimeterCountCellLeft.right
                                anchors.bottom: perimeterCountCellLeft.bottom

                                ComboBox
                                {
                                    id: perimeterCountCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbItems
                                        ListElement { text: "1"; value: 1 }
                                        ListElement { text: "2"; value: 2 }
                                        ListElement { text: "3"; value: 3 }
                                        ListElement { text: "4"; value: 4 }
                                        ListElement { text: "5"; value: 5 }
                                        ListElement { text: "6"; value: 6 }
                                        ListElement { text: "7"; value: 7 }
                                        ListElement { text: "8"; value: 8 }
                                    }

                                    currentIndex:
                                    {
                                        var pC = perimeterCount.properties.value
                                        for(var i = 0; i < cbItems.count; ++i)
                                        {
                                            if(model.get(i).value == pC)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: perimeterCount.setPropertyValue("value", model.get(index).value)

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
                        id: topSolidLayerCountRow

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
                                id: topSolidLayerCountCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: topSolidLayerCountLabel
                                    text: catalog.i18nc("@label", "Top solid layer count")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: topSolidLayerCountLabel.right; verticalCenter:  topSolidLayerCountLabel.verticalCenter; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 4)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                id: topSolidLayerCountCellRight

                                width: Math.round(base.width * .38)
                                height: topSolidLayerCountCellLeft.height

                                anchors.left: topSolidLayerCountCellLeft.right
                                anchors.bottom: topSolidLayerCountCellLeft.bottom

                                ComboBox
                                {
                                    id: topSolidLayerCountCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbTSLCItems
                                        ListElement { text: "0";  value: 0  }
                                        ListElement { text: "1";  value: 1  }
                                        ListElement { text: "2";  value: 2  }
                                        ListElement { text: "3";  value: 3  }
                                        ListElement { text: "4";  value: 4  }
                                        ListElement { text: "5";  value: 5  }
                                        ListElement { text: "6";  value: 6  }
                                        ListElement { text: "7";  value: 7  }
                                        ListElement { text: "8";  value: 8  }
                                        ListElement { text: "12"; value: 12 }
                                        ListElement { text: "16"; value: 16 }
                                    }

                                    currentIndex:
                                    {
                                        var tSLC = topSolidLayerCount.properties.value
                                        for(var i = 0; i < cbTSLCItems.count; ++i)
                                        {
                                            if(model.get(i).value == tSLC)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: topSolidLayerCount.setPropertyValue("value", model.get(index).value)

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
                        id: bottomSolidLayerCountRow

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
                                id: bottomSolidLayerCountCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: bottomSolidLayerCountLabel
                                    text: catalog.i18nc("@label", "Bottom solid layer count")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: bottomSolidLayerCountLabel.right; verticalCenter:  bottomSolidLayerCountLabel.verticalCenter; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 4)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                id: bottomSolidLayerCountCellRight

                                width: Math.round(base.width * .38)
                                height: bottomSolidLayerCountCellLeft.height

                                anchors.left: bottomSolidLayerCountCellLeft.right
                                anchors.bottom: bottomSolidLayerCountCellLeft.bottom

                                ComboBox
                                {
                                    id: bottomSolidLayerCountCB
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 100

                                    model: ListModel {
                                        id: cbBSLCItems
                                        ListElement { text: "0";  value: 0  }
                                        ListElement { text: "1";  value: 1  }
                                        ListElement { text: "2";  value: 2  }
                                        ListElement { text: "3";  value: 3  }
                                        ListElement { text: "4";  value: 4  }
                                        ListElement { text: "5";  value: 5  }
                                        ListElement { text: "6";  value: 6  }
                                        ListElement { text: "7";  value: 7  }
                                        ListElement { text: "8";  value: 8  }
                                        ListElement { text: "12"; value: 12 }
                                        ListElement { text: "16"; value: 16 }
                                    }

                                    currentIndex:
                                    {
                                        var bSLC = bottomSolidLayerCount.properties.value
                                        for(var i = 0; i < cbBSLCItems.count; ++i)
                                        {
                                            if(model.get(i).value == bSLC)
                                            {
                                                return i
                                            }
                                        }
                                    }

                                    onActivated: bottomSolidLayerCount.setPropertyValue("value", model.get(index).value)

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
                        id: fanSpeedRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 51
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: fanSpeedCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: fanSpeedLabel
                                    text: catalog.i18nc("@label", "Fan speed")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: fanSpeedLabel.right; top: fanSpeedLabel.top; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 5)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                id: fanSpeedCellRight

                                width: Math.round(base.width * .38)
                                height: fanSpeedCellLeft.height

                                anchors.left: fanSpeedCellLeft.right
                                anchors.bottom: fanSpeedCellLeft.bottom

                                Label
                                {
                                    id: selectedfanSpeedText

                                    anchors.bottom: parent.bottom
                                    anchors.left: fanSpeedSlider.left
                                    anchors.right: parent.right

                                    font: UM.Theme.getFont("medium")

                                    text: parseInt(coolFanSpeedMax.properties.value) == 0 ? catalog.i18nc("@label", "Fan off") : "%" + coolFanSpeedMax.properties.value

                                    color: fanSpeedSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                }

                                Slider
                                {
                                    id: fanSpeedSlider

                                    anchors.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height / 2
                                    anchors.bottom: selectedfanSpeedText.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    height: UM.Theme.getSize("sidebar_margin").height

                                    updateValueWhileDragging : true


                                    width: parseInt(fanSpeedCellRight.width - UM.Theme.getSize("sidebar_margin").width - style.handleWidth)

                                    minimumValue: 0
                                    maximumValue: 100
                                    stepSize: 1

                                    value: parseInt(coolFanSpeedMax.properties.value)

                                    onValueChanged: {

                                        // Don't round the value if it's already the same
                                        if (parseInt(coolFanSpeedMax.properties.value) == fanSpeedSlider.value) {
                                            return
                                        }

                                        // Round the slider value to the nearest multiple of 10 (simulate step size of 10)
                                        var roundedSliderValue = Math.round(fanSpeedSlider.value / 10) * 10

                                        // Update the slider value to represent the rounded value
                                        fanSpeedSlider.value = roundedSliderValue

                                        Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_min", "value", roundedSliderValue)
                                        Cura.MachineManager.setSettingForAllExtruders("cool_fan_speed_max", "value", roundedSliderValue)
                                    }


                                    style: SliderStyle
                                    {
                                        groove: Rectangle {
                                            id: groove
                                            implicitWidth: 100 * screenScaleFactor
                                            implicitHeight: 10 * screenScaleFactor
                                            color: control.enabled ? UM.Theme.getColor("slider_groove") : UM.Theme.getColor("quality_slider_unavailable")
                                            radius: 5
                                        }

                                        handle: Item {
                                            Rectangle {
                                                id: handleButton
                                                anchors.centerIn: parent
                                                color: control.enabled ? UM.Theme.getColor("slider_handle") : UM.Theme.getColor("quality_slider_unavailable")
                                                implicitWidth: 15 * screenScaleFactor
                                                implicitHeight: 15 * screenScaleFactor
                                                radius: 100
                                            }
                                        }
                                    }

                                    Component.onCompleted: {
                                        // Disable mouse wheel on old sliders.
                                        for (var i = 0; i < fanSpeedSlider.children.length; ++i) {
                                            if (fanSpeedSlider.children[i].hasOwnProperty("onVerticalWheelMoved") && fanSpeedSlider.children[i].hasOwnProperty("onHorizontalWheelMoved")) {
                                                fanSpeedSlider.children[i].destroy()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: xyToleranceRow

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 51
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: xyToleranceCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: xyToleranceLabel
                                    text: catalog.i18nc("@label", "XY tolerance")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: xyToleranceLabel.right; top: xyToleranceLabel.top; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 6)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                id: xyToleranceCellRight

                                width: Math.round(base.width * .38)
                                height: xyToleranceCellLeft.height

                                anchors.left: xyToleranceCellLeft.right
                                anchors.bottom: xyToleranceCellLeft.bottom

                                Label
                                {
                                    id: selectedxyToleranceText

                                    anchors.bottom: parent.bottom
                                    anchors.left: xyToleranceSlider.left
                                    anchors.right: parent.right

                                    font: UM.Theme.getFont("medium")

                                    text: parseFloat(xyTolerance.properties.value) + " mm"

                                    color: xyToleranceSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                }

                                Slider
                                {
                                    id: xyToleranceSlider

                                    anchors.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height / 2
                                    anchors.bottom: selectedxyToleranceText.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    height: UM.Theme.getSize("sidebar_margin").height

                                    updateValueWhileDragging : true


                                    width: parseInt(xyToleranceCellRight.width - UM.Theme.getSize("sidebar_margin").width - style.handleWidth)

                                    minimumValue: -1
                                    maximumValue: 1
                                    stepSize: 0.01

                                    value: parseFloat(xyTolerance.properties.value)

                                    onValueChanged: {
                                        xyTolerance.setPropertyValue("value", xyToleranceSlider.value);
                                        xyToleranceLayer0.setPropertyValue("value", xyToleranceSlider.value);
                                    }


                                    style: SliderStyle
                                    {
                                        groove: Rectangle {
                                            id: groove
                                            implicitWidth: 100 * screenScaleFactor
                                            implicitHeight: 10 * screenScaleFactor
                                            color: control.enabled ? UM.Theme.getColor("slider_groove") : UM.Theme.getColor("quality_slider_unavailable")
                                            radius: 5
                                        }

                                        handle: Item {
                                            Rectangle {
                                                id: handleButton
                                                anchors.centerIn: parent
                                                color: control.enabled ? UM.Theme.getColor("slider_handle") : UM.Theme.getColor("quality_slider_unavailable")
                                                implicitWidth: 15 * screenScaleFactor
                                                implicitHeight: 15 * screenScaleFactor
                                                radius: 100
                                            }
                                        }
                                    }

                                    Component.onCompleted: {
                                        // Disable mouse wheel on old sliders.
                                        for (var i = 0; i < xyToleranceSlider.children.length; ++i) {
                                            if (xyToleranceSlider.children[i].hasOwnProperty("onVerticalWheelMoved") && xyToleranceSlider.children[i].hasOwnProperty("onHorizontalWheelMoved")) {
                                                xyToleranceSlider.children[i].destroy()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: supportContactDistanceRow
                        visible: false // not visible until it gets figured out

                        Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                        Layout.preferredHeight: 51
                        Layout.alignment: Qt.AlignLeft

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            color: UM.Theme.getColor("sidebar_item_light")
                            width: parent.width
                            Item
                            {
                                id: supportContactDistanceCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .45)

                                Label
                                {
                                    id: supportContactDistanceLabel
                                    text: catalog.i18nc("@label", "Support contact distance")
                                    font: UM.Theme.getFont("medium");
                                    color: UM.Theme.getColor("text_sidebar")

                                    anchors.top: parent.top
                                    anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: supportContactDistanceLabel.right; top: supportContactDistanceLabel.top; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 9)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }

                            Item
                            {
                                id: supportContactDistanceCellRight

                                width: Math.round(base.width * .38)
                                height: supportContactDistanceCellLeft.height

                                anchors.left: supportContactDistanceCellLeft.right
                                anchors.bottom: supportContactDistanceCellLeft.bottom

                                Label
                                {
                                    id: selectedsupportContactDistanceText

                                    anchors.bottom: parent.bottom
                                    anchors.left: supportContactDistanceSlider.left
                                    anchors.right: parent.right

                                    font: UM.Theme.getFont("medium")

                                    text: parseFloat(supportContactDistance.properties.value) + " mm"

                                    color: supportContactDistanceSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                }

                                Slider
                                {
                                    id: supportContactDistanceSlider

                                    anchors.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height / 2
                                    anchors.bottom: selectedsupportContactDistanceText.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right

                                    height: UM.Theme.getSize("sidebar_margin").height

                                    updateValueWhileDragging : true


                                    width: parseInt(supportContactDistanceCellRight.width - UM.Theme.getSize("sidebar_margin").width - style.handleWidth)

                                    minimumValue: 0
                                    maximumValue: 0.4
                                    stepSize: 0.1

                                    value: parseFloat(supportContactDistance.properties.value)

                                    onValueChanged: {
                                        supportContactDistance.setPropertyValue("value", supportContactDistanceSlider.value);
                                    }


                                    style: SliderStyle
                                    {
                                        groove: Rectangle {
                                            id: groove
                                            implicitWidth: 100 * screenScaleFactor
                                            implicitHeight: 10 * screenScaleFactor
                                            color: control.enabled ? UM.Theme.getColor("slider_groove") : UM.Theme.getColor("quality_slider_unavailable")
                                            radius: 5
                                        }

                                        handle: Item {
                                            Rectangle {
                                                id: handleButton
                                                anchors.centerIn: parent
                                                color: control.enabled ? UM.Theme.getColor("slider_handle") : UM.Theme.getColor("quality_slider_unavailable")
                                                implicitWidth: 15 * screenScaleFactor
                                                implicitHeight: 15 * screenScaleFactor
                                                radius: 100
                                            }
                                        }
                                    }

                                    Component.onCompleted: {
                                        // Disable mouse wheel on old sliders.
                                        for (var i = 0; i < supportContactDistanceSlider.children.length; ++i) {
                                            if (supportContactDistanceSlider.children[i].hasOwnProperty("onVerticalWheelMoved") && supportContactDistanceSlider.children[i].hasOwnProperty("onHorizontalWheelMoved")) {
                                                supportContactDistanceSlider.children[i].destroy()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    /*Item
                    {
                        id: seamToBackRow

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
                                id: seamToBackCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .70)

                                CheckBox
                                {
                                    id: seamToBackCheckBox
                                    property alias _hovered: seamToBackMouseArea.containsMouse
                                    property bool checkBoxSmall: true

                                    anchors.top: parent.top
                                    anchors.left: parent.left

                                    //: Setting enable printing build-plate adhesion helper checkbox
                                    style: UM.Theme.styles.checkbox;

                                    checked: zSeamType.properties.value == "back"
                                    text: catalog.i18nc("@label", "Seam on back")

                                    MouseArea
                                    {
                                        id: seamToBackMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked:
                                        {
                                            parent.checked = !parent.checked;
                                            zSeamType.setPropertyValue("value", parent.checked ? "back" : "shortest");
                                        }
                                    }
                                }
                            }
                        }
                    }*/

                    Item
                    {
                        id: zHopWhenRetractedRow

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
                                id: zHopWhenRetractedCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .70)

                                CheckBox
                                {
                                    id: zHopWhenRetractedCheckBox
                                    property alias _hovered: zHopWhenRetractedMouseArea.containsMouse
                                    property bool checkBoxSmall: true

                                    anchors.top: parent.top
                                    anchors.left: parent.left

                                    //: Setting enable printing build-plate adhesion helper checkbox
                                    style: UM.Theme.styles.checkbox;

                                    checked: zHopWhenRetracted.properties.value == "True"
                                    text: catalog.i18nc("@label", "Z hop when retracted")

                                    MouseArea
                                    {
                                        id: zHopWhenRetractedMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked:
                                        {
                                            parent.checked = !parent.checked;
                                            zHopWhenRetracted.setPropertyValue("value", booleanToString(parent.checked));
                                        }
                                    }
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: zHopWhenRetractedCheckBox.right; verticalCenter: zHopWhenRetractedCheckBox.verticalCenter; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 10)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item
                    {
                        id: spiralVaseModeRow

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
                                id: spiralVaseModeCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .70)

                                CheckBox
                                {
                                    id: spiralVaseModeCheckBox
                                    property alias _hovered: spiralVaseModeMouseArea.containsMouse
                                    property bool checkBoxSmall: true

                                    anchors.top: parent.top
                                    anchors.left: parent.left

                                    //: Setting enable printing build-plate adhesion helper checkbox
                                    style: UM.Theme.styles.checkbox;

                                    checked: spiralVaseMode.properties.value == "True"
                                    text: catalog.i18nc("@label", "Spiral vase mode")

                                    MouseArea
                                    {
                                        id: spiralVaseModeMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked:
                                        {
                                            parent.checked = !parent.checked;
                                            spiralVaseMode.setPropertyValue("value", booleanToString(parent.checked));
                                        }
                                    }
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: spiralVaseModeCheckBox.right; verticalCenter: spiralVaseModeCheckBox.verticalCenter; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 8)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    /*
                    Item
                    {
                        id: avoidSupportsRow

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
                                id: avoidSupportsCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .70)

                                CheckBox
                                {
                                    id: avoidSupportsCheckBox
                                    property alias _hovered: avoidSupportsMouseArea.containsMouse
                                    property bool checkBoxSmall: true

                                    anchors.top: parent.top
                                    anchors.left: parent.left

                                    //: Setting enable printing build-plate adhesion helper checkbox
                                    style: UM.Theme.styles.checkbox;

                                    checked: avoidSupports.properties.value == "True"
                                    text: catalog.i18nc("@label", "Avoid supports")

                                    MouseArea
                                    {
                                        id: avoidSupportsMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked:
                                        {
                                            parent.checked = !parent.checked;
                                            avoidSupports.setPropertyValue("value", booleanToString(parent.checked));
                                        }
                                    }
                                }
                                Image
                                {
                                    width: 11; height: 12

                                    source: UM.Theme.getImage("info")

                                    anchors { left: avoidSupportsCheckBox.right; verticalCenter: avoidSupportsCheckBox.verticalCenter; leftMargin: 5 }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor

                                        onClicked:
                                        {
                                            UM.Preferences.setValue("cura/help_page", 7)
                                            UM.Controller.setActiveStage("Help")
                                        }
                                    }
                                }
                            }
                        }
                    }*/

                    Item
                    {
                        id: outerInsetFirstRow

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
                                id: outerInsetFirstCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .70)

                                CheckBox
                                {
                                    id: outerInsetFirstCheckBox
                                    property alias _hovered: outerInsetFirstMouseArea.containsMouse
                                    property bool checkBoxSmall: true

                                    anchors.top: parent.top
                                    anchors.left: parent.left

                                    //: Setting enable printing build-plate adhesion helper checkbox
                                    style: UM.Theme.styles.checkbox;

                                    checked: outerInsetFirst.properties.value == "True"
                                    text: catalog.i18nc("@label", "Outer wall first")

                                    MouseArea
                                    {
                                        id: outerInsetFirstMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked:
                                        {
                                            parent.checked = !parent.checked;
                                            outerInsetFirst.setPropertyValue("value", booleanToString(parent.checked));
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item
                    {
                        id: slicingToleranceRow

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
                                id: slicingToleranceCellLeft

                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom

                                width: Math.round(base.width * .70)

                                CheckBox
                                {
                                    id: slicingToleranceCheckBox
                                    property alias _hovered: slicingToleranceMouseArea.containsMouse
                                    property bool checkBoxSmall: true

                                    anchors.top: parent.top
                                    anchors.left: parent.left

                                    //: Setting enable printing build-plate adhesion helper checkbox
                                    style: UM.Theme.styles.checkbox;

                                    checked: slicingTolerance.properties.value == "exclusive"
                                    text: catalog.i18nc("@label", "More detailed slicing")

                                    MouseArea
                                    {
                                        id: slicingToleranceMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked:
                                        {
                                            parent.checked = !parent.checked;
                                            slicingTolerance.setPropertyValue("value", parent.checked ? "exclusive" : "middle");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //
            // Advanced settings button
            //
            Item
            {
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: childrenRect.height
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Button {
                    id: advancedSettingsButton
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "Advanced settings")
                    onClicked: {
                        if (advancedSettingsPane.visible) {
                            advancedSettingsPane.visible = false
                            advancedSettingsButton.text = catalog.i18nc("@label", "Advanced settings")
                        } else {
                            advancedSettingsPane.visible = true
                            advancedSettingsButton.text = catalog.i18nc("@label", "Hide advanced settings")
                        }
                    }
                    anchors.right: parent.right
                    anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width * 2
                }
            }
            // Bottom Border
            Rectangle { Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_item_margin").width * 2); Layout.alignment: Qt.AlignHCenter; height: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

            // Button row
            RowLayout {
                implicitWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 120
                Layout.alignment: Qt.AlignHCenter
                spacing: UM.Theme.getSize("sidebar_margin").width
                Button {
                    id: cancelButton
                    property bool cancelButton: true
                    style: UM.Theme.styles.sidebar_button
                    text: catalog.i18nc("@label", "Cancel")
                    onClicked: {
                        CuraApplication.backend.stopSlicing();
                        UM.Controller.setActiveStage("NetworkMachineList")

                        if (UM.Preferences.getValue("general/firstrun"))
                            UM.Preferences.setValue("general/firstrun_step", 4)
                    }
                    Layout.alignment: Qt.AlignRight
                }
                Button {
                    id: sliceButton
                    style: UM.Theme.styles.sidebar_button
                    text: catalog.i18nc("@label", "Slice!")
                    onClicked: {
                        CuraApplication.backend.forceSlice();
                    }
                    Layout.alignment: Qt.AlignLeft
                }
            }

            UM.SettingPropertyProvider
            {
                id: infillExtruderNumber
                containerStackId: Cura.MachineManager.activeStackId
                key: "infill_extruder_nr"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: coolFanSpeedMin
                containerStackId: Cura.MachineManager.activeStackId
                key: "cool_fan_speed_min"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: coolFanSpeedMax
                containerStackId: Cura.MachineManager.activeStackId
                key: "cool_fan_speed_max"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: xyTolerance
                containerStackId: Cura.MachineManager.activeStackId
                key: "xy_offset"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: supportContactDistance
                containerStackId: Cura.MachineManager.activeStackId
                key: "support_z_distance"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: xyToleranceLayer0
                containerStackId: Cura.MachineManager.activeStackId
                key: "xy_offset_layer_0"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: zHopWhenRetracted
                containerStackId: Cura.MachineManager.activeStackId
                key: "retraction_hop_enabled"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: spiralVaseMode
                containerStackId: Cura.MachineManager.activeMachineId
                key: "magic_spiralize"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: avoidSupports
                containerStackId: Cura.MachineManager.activeStackId
                key: "conical_overhang_enabled"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: outerInsetFirst
                containerStackId: Cura.MachineManager.activeStackId
                key: "outer_inset_first"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: slicingTolerance
                containerStackId: Cura.MachineManager.activeStackId
                key: "slicing_tolerance"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: infillPattern
                containerStackId: Cura.MachineManager.activeStackId
                key: "infill_pattern"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: infillDensity
                containerStackId: Cura.MachineManager.activeStackId
                key: "infill_sparse_density"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: infillSteps
                containerStackId: Cura.MachineManager.activeStackId
                key: "gradual_infill_steps"
                watchedProperties: ["value", "enabled"]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: zSeamType
                containerStackId: Cura.MachineManager.activeStackId
                key: "z_seam_type"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: zSeamCorner
                containerStackId: Cura.MachineManager.activeStackId
                key: "z_seam_corner"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }
            UM.SettingPropertyProvider
            {
                id: platformAdhesionType
                containerStack: Cura.MachineManager.activeMachine
                key: "adhesion_type"
                watchedProperties: [ "value", "enabled" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: supportEnabled
                containerStack: Cura.MachineManager.activeMachine
                key: "support_enable"
                watchedProperties: [ "value", "enabled", "description" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: supportAngle
                containerStack: Cura.MachineManager.activeMachine
                key: "support_angle"
                watchedProperties: [ "value", "enabled", "description" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: supportSkipSomeZags
                containerStack: Cura.MachineManager.activeMachine
                key: "support_skip_some_zags"
                watchedProperties: [ "value", "enabled" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: initialLayerLineWidthFactor
                containerStack: Cura.MachineManager.activeMachine
                key: "initial_layer_line_width_factor"
                watchedProperties: [ "value", "enabled" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: speedPrintLayer0
                containerStack: Cura.MachineManager.activeMachine
                key: "speed_print_layer_0"
                watchedProperties: [ "value", "enabled" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: speedWall0
                containerStack: Cura.MachineManager.activeMachine
                key: "speed_wall_0"
                watchedProperties: [ "value", "enabled" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: perimeterCount
                containerStack: Cura.MachineManager.activeMachine
                key: "wall_line_count"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: topSolidLayerCount
                containerStack: Cura.MachineManager.activeMachine
                key: "top_layers"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: bottomSolidLayerCount
                containerStack: Cura.MachineManager.activeMachine
                key: "bottom_layers"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: extrudersEnabledCount
                containerStack: Cura.MachineManager.activeMachine
                key: "extruders_enabled_count"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            UM.SettingPropertyProvider
            {
                id: supportExtruderNr
                containerStack: Cura.MachineManager.activeMachine
                key: "support_extruder_nr"
                watchedProperties: [ "value" ]
                storeIndex: 0
            }

            ListModel
            {
                id: extruderModel
                Component.onCompleted: populateExtruderModel()
            }

            //: Model used to populate the extrudelModel
            Cura.ExtrudersModel
            {
                id: extruders
                onModelChanged: populateExtruderModel()
            }
        }
    }

    function populateExtruderModel()
    {
        extruderModel.clear();
        for(var extruderNumber = 0; extruderNumber < extruders.rowCount(); extruderNumber++)
        {
            extruderModel.append({
                text: catalog.i18nc("@label", extruders.getItem(extruderNumber).name),
                color: extruders.getItem(extruderNumber).color
            })
        }
        supportExtruderCombobox.updateCurrentColor();
    }

    Connections {
        target: UM.Preferences
        onPreferenceChanged:
        {
            if (UM.Preferences.getValue("general/firstrun")) {
                switch(UM.Preferences.getValue("general/firstrun_step")) {
                    case 6:
                        base.showFirstrunTip(
                            qualityLabel.mapToItem(base, 0, -5),
                            catalog.i18nc("@firstrun", "Slicing Options"),
                            catalog.i18nc("@firstrun", "Adjust layer height (resolution), infill density, raft and fill density according to needs. Then hit the Slice! button when ready!"), false, "")
                        break
                }
            }
        }
    }
}
