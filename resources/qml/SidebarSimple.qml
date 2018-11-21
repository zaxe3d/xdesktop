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

    property Action configureSettings;
    property int backendState: UM.Backend.state
    property bool settingsEnabled: Cura.ExtruderManager.activeExtruderStackId || extrudersEnabledCount.properties.value == 1
    UM.I18nCatalog { id: catalog; name: "cura" }

    Connections {
        target: CuraApplication
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
                    radius: 2
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
                    radius: 2
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

                            // we loop over all density icons and only show the one that has the current density and steps
                            Repeater
                            {
                                id: supportAngleIconList
                                //model: supportAngleModel
                                anchors.fill: parent

                                function activeIndex () {
                                    for (var i = 0; i < supportAngleModel.count; i++) {
                                        var density = Math.round(supportAngle.properties.value)
                                        var steps = Math.round(supportAngleSteps.properties.value)
                                        var supportAngleModelItem = supportAngleModel.get(i)

                                        if (supportAngleModelItem != "undefined"
                                            && density >= supportAngleModelItem.percentageMin
                                            && density <= supportAngleModelItem.percentageMax
                                            && steps >= supportAngleModelItem.stepsMin
                                            && steps <= supportAngleModelItem.stepsMax
                                        ){
                                            return i
                                        }
                                    }
                                    return -1
                                }

                                Rectangle
                                {
                                    anchors.fill: parent
                                    visible: supportAngleIconList.activeIndex() == index

                                    border.width: UM.Theme.getSize("default_lining").width
                                    border.color: UM.Theme.getColor("quality_slider_unavailable")
                                    radius: 5

                                    UM.RecolorImage {
                                        anchors.fill: parent
                                        anchors.margins: 2 * screenScaleFactor
                                        sourceSize.width: width
                                        sourceSize.height: width
                                        source: UM.Theme.getIcon(model.icon)
                                        color: UM.Theme.getColor("quality_slider_unavailable")
                                    }
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

                            text: supportAngle.properties.value > 0 ? parseInt(supportAngle.properties.value) + "°" : catalog.i18nc("@label", "Support off")

                            color: supportAngleSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                        }

                        // We use a binding to make sure that after manually setting supportAngleSlider.value it is still bound to the property provider
                        Binding {
                            target: supportAngleSlider
                            property: "value"
                            value: parseInt(supportAngle.properties.value)
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
                            maximumValue: 100
                            stepSize: 1
                            tickmarksEnabled: false

                            // set initial value from stack
                            value: parseInt(supportAngle.properties.value)

                            onValueChanged: {


                                // Round the slider value to the nearest multiple of 10 (simulate step size of 10)
                                var roundedSliderValue = Math.round(supportAngleSlider.value / 10) * 10

                                // Update the slider value to represent the rounded value
                                supportAngleSlider.value = roundedSliderValue

                                supportEnabled.setPropertyValue("value", (roundedSliderValue > 0))

                                // only set if different
                                if (parseInt(supportAngle.properties.value) != supportAngleSlider.value) {
                                    supportAngle.setPropertyValue("value", roundedSliderValue)
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
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    anchors.fill: parent
                    color: UM.Theme.getColor("sidebar_item_light")
                    radius: 2
                    width: parent.width
                    Item
                    {
                        id: raftCellLeft

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom

                        width: Math.round(base.width * .27)

                        Image {
                            antialiasing: true
                            visible: platformAdhesionType.properties.value == "none"
                            width: 75; height: 75
                            anchors.top: parent.top; anchors.left: parent.left
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_icon_margin").height
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_icon_margin").width
                            source: "../../plugins/NetworkMachineList/resources/images/raft/off.png"
                        }
                        Image {
                            antialiasing: true
                            visible: platformAdhesionType.properties.value == "raft"
                            width: 75; height: 75
                            anchors.top: raftLabel.bottom; anchors.left: parent.left
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_icon_margin").height
                            anchors.leftMargin: UM.Theme.getSize("sidebar_item_icon_margin").width
                            source: "../../plugins/NetworkMachineList/resources/images/raft/on.png"
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
                    radius: 2
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

                            // we loop over all density icons and only show the one that has the current density and steps
                            Repeater
                            {
                                id: infillIconList
                                model: infillModel
                                anchors.fill: parent

                                function activeIndex () {
                                    for (var i = 0; i < infillModel.count; i++) {
                                        var density = Math.round(infillDensity.properties.value)
                                        var steps = Math.round(infillSteps.properties.value)
                                        var infillModelItem = infillModel.get(i)

                                        if (infillModelItem != "undefined"
                                            && density >= infillModelItem.percentageMin
                                            && density <= infillModelItem.percentageMax
                                            && steps >= infillModelItem.stepsMin
                                            && steps <= infillModelItem.stepsMax
                                        ){
                                            return i
                                        }
                                    }
                                    return -1
                                }

                                Rectangle
                                {
                                    anchors.fill: parent
                                    visible: infillIconList.activeIndex() == index

                                    border.width: UM.Theme.getSize("default_lining").width
                                    border.color: UM.Theme.getColor("text_blue")
                                    radius: 5

                                    UM.RecolorImage {
                                        anchors.fill: parent
                                        anchors.margins: 2 * screenScaleFactor
                                        sourceSize.width: width
                                        sourceSize.height: width
                                        source: UM.Theme.getIcon(model.icon)
                                        color: UM.Theme.getColor("text_blue")
                                    }
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
                        }


                        //  Infill list model for mapping icon
                        ListModel
                        {
                            id: infillModel
                            Component.onCompleted:
                            {
                                infillModel.append({
                                    percentageMin: -1,
                                    percentageMax: 0,
                                    stepsMin: -1,
                                    stepsMax: 0,
                                    icon: "hollow"
                                })
                                infillModel.append({
                                    percentageMin: 0,
                                    percentageMax: 40,
                                    stepsMin: -1,
                                    stepsMax: 0,
                                    icon: "sparse"
                                })
                                infillModel.append({
                                    percentageMin: 40,
                                    percentageMax: 89,
                                    stepsMin: -1,
                                    stepsMax: 0,
                                    icon: "dense"
                                })
                                infillModel.append({
                                    percentageMin: 90,
                                    percentageMax: 9999999999,
                                    stepsMin: -1,
                                    stepsMax: 0,
                                    icon: "solid"
                                })
                                infillModel.append({
                                    percentageMin: 0,
                                    percentageMax: 9999999999,
                                    stepsMin: 1,
                                    stepsMax: 9999999999,
                                    icon: "gradual"
                                })
                            }
                        }
                    }
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
                        CuraApplication.backend.forceSlice();
                        UM.Controller.setActiveStage("NetworkMachineList")
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
