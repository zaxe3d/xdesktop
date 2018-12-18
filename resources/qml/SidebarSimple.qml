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

    signal showTooltip(Item item, point location, string text);
    signal hideTooltip();

    property int backendState: UM.Backend.state
    property bool settingsEnabled: Cura.ExtruderManager.activeExtruderStackId || extrudersEnabledCount.properties.value == 1
    property int  supportAngle: UM.Preferences.getValue("slicing/support_angle")
    property bool supportEnabled: UM.Preferences.getValue("slicing/support_angle") > 0

    UM.I18nCatalog { id: catalog; name: "cura" }

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
            spacing: UM.Theme.getSize("sidebar_spacing").height

            //
            // Quality profile
            //
            Item
            {
                id: qualityRow

                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 125
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
                                if (Cura.SimpleModeSettingsManager.isProfileUserCreated)
                                {
                                    qualityModel.qualitySliderActiveIndex = -1
                                }
                                else
                                {
                                    qualityModel.qualitySliderActiveIndex = i
                                }

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
                            font: UM.Theme.getFont("large");
                            color: UM.Theme.getColor("text_sidebar")

                            anchors.top: parent.top
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                        }
                        Rectangle
                        {
                            id: qualityIcon

                            width: 75; height: width
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
                        anchors.bottomMargin: 12

                        Label
                        {
                            id: selectedQualityText

                            anchors.bottom: parent.bottom
                            anchors.left: qualitySlider.left
                            anchors.leftMargin: Math.round((qualitySlider.value / qualitySlider.stepSize) * (qualitySlider.width / (qualitySlider.maximumValue / qualitySlider.stepSize)) - 10 * screenScaleFactor)
                            anchors.right: parent.right

                            font: UM.Theme.getFont("large_semi_bold")

                            text: Cura.QualityProfilesDropDownMenuModel.getItem(qualitySlider.value).layer_height + " mm"

                            color: qualitySlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
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
                Layout.preferredHeight: 125
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
                            font: UM.Theme.getFont("large");
                            color: UM.Theme.getColor("text_sidebar")

                            anchors.top: parent.top
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                        }
                        Rectangle
                        {
                            id: supportAngleIcon

                            width: 75; height: width
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

                            font: UM.Theme.getFont("large_semi_bold")

                            text: base.supportEnabled ? base.supportAngle + "°" : catalog.i18nc("@label", "Support off")

                            color: supportAngleSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
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
                Layout.preferredHeight: 75
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

                            width: 75; height: width
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
                            enabled: base.settingsEnabled

                            visible: platformAdhesionType.properties.enabled == "True"
                            checked: platformAdhesionType.properties.value == "raft"
                            text: catalog.i18nc("@label", "Raft")

                            MouseArea
                            {
                                id: adhesionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: base.settingsEnabled
                                onClicked:
                                {
                                    parent.checked = !parent.checked;
                                    var adhesionType = parent.checked ? "raft" : "none";
                                    platformAdhesionType.setPropertyValue("value", adhesionType);
                                    initialLayerLineWidthFactor.setPropertyValue("value", adhesionType == "raft" ? "100" : "150");
                                }
                                onEntered:
                                {
                                    base.showTooltip(adhesionCheckBox, Qt.point(-adhesionCheckBox.x, 0),
                                        catalog.i18nc("@label", "Enable printing a brim or raft. This will add a flat area around or under your object which is easy to cut off afterwards."));
                                }
                                onExited:
                                {
                                    base.hideTooltip();
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
                Layout.preferredHeight: 125
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
                        Rectangle
                        {
                            id: infillIcon

                            width: 75; height: width
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

                            font: UM.Theme.getFont("large_semi_bold")

                            text: "%" + parseInt(infillDensity.properties.value)

                            color: infillSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
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

                                // Round the slider value to the nearest multiple of 10 (simulate step size of 10)
                                var roundedSliderValue = Math.round(infillSlider.value / 10) * 10

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
                                        ListElement { text: "0"; value: 0 }
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
                                        ListElement { text: "0"; value: 0 }
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
                                    anchors.leftMargin: Math.round((fanSpeedSlider.value / fanSpeedSlider.stepSize) * (fanSpeedSlider.width / (fanSpeedSlider.maximumValue / fanSpeedSlider.stepSize)) - 10 * screenScaleFactor)
                                    anchors.right: parent.right

                                    font: UM.Theme.getFont("medium")

                                    text: "%" + parseInt(coolFanSpeedMax.properties.value)

                                    color: fanSpeedSlider.enabled ? UM.Theme.getColor("fanSpeed_slider_available") : UM.Theme.getColor("fanSpeed_slider_unavailable")
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
                Layout.preferredHeight: 125
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
                    }
                    Layout.alignment: Qt.AlignRight
                }
                Button {
                    id: sliceButton
                    style: UM.Theme.styles.sidebar_button
                    text: catalog.i18nc("@label", "Slice!")
                    onClicked: {
                        UM.Controller.setActiveStage("NetworkMachineList")
                        CuraApplication.backend.forceSlice();
                        UM.Controller.setActiveView("SimulationView")
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
        }
    }
}
