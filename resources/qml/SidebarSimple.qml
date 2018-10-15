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
                Layout.preferredHeight: 75
                Layout.alignment: Qt.AlignHCenter

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


                // Background
                RectangularGlow {
                    height: 75

                    anchors.fill: parent
                    glowRadius: 3
                    spread: 0
                    color: UM.Theme.getColor("sidebar_item_glow")
                    cornerRadius: 2

                    Rectangle {
                        anchors.fill: parent
                        color: UM.Theme.getColor("sidebar_item")
                        radius: 2
                        width: parent.width
                        Label
                        {
                            id: qualityRowTitle
                            text: catalog.i18nc("@label", "Layer Height")
                            font: UM.Theme.getFont("default")
                            anchors {
                                top: parent.top; left: parent.left
                                topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            color: UM.Theme.getColor("text_sidebar")
                        }

                        // Show titles for the each quality slider ticks
                        Item
                        {
                            y: 3;
                            anchors.left: speedSlider.left
                            Repeater
                            {
                                model: qualityModel

                                Label
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: Math.round(UM.Theme.getSize("sidebar_margin").height / 2)
                                    color: (Cura.MachineManager.activeMachine != null && Cura.QualityProfilesDropDownMenuModel.getItem(index).available) ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                    text:
                                    {
                                        var result = ""
                                        if(Cura.MachineManager.activeMachine != null)
                                        {
                                            result = Cura.QualityProfilesDropDownMenuModel.getItem(index).layer_height

                                            if(result == undefined)
                                            {
                                                result = "";
                                            }
                                            else
                                            {
                                                result = Number(Math.round(result + "e+2") + "e-2"); //Round to 2 decimals. Javascript makes this difficult...
                                                if (result == undefined || result != result) //Parse failure.
                                                {
                                                    result = "";
                                                }
                                            }
                                        }
                                        return result
                                    }

                                    x:
                                    {
                                        // Make sure the text aligns correctly with each tick
                                        if (qualityModel.totalTicks == 0)
                                        {
                                            // If there is only one tick, align it centrally
                                            return Math.round(((base.width * 0.55) - width) / 2)
                                        }
                                        else if (index == 0)
                                        {
                                            return Math.round(base.width * 0.55 / qualityModel.totalTicks) * index
                                        }
                                        else if (index == qualityModel.totalTicks)
                                        {
                                            return Math.round(base.width * 0.55 / qualityModel.totalTicks) * index - width
                                        }
                                        else
                                        {
                                            return Math.round((base.width * 0.55 / qualityModel.totalTicks) * index - (width / 2))
                                        }
                                    }
                                }
                            }
                        }

                        //Print speed slider
                        Item
                        {
                            id: speedSlider
                            width: Math.round(base.width * 0.55)
                            height: UM.Theme.getSize("sidebar_margin").height
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height * 2
                            anchors.rightMargin: UM.Theme.getSize("sidebar_item_margin").width

                            // This Item is used only for tooltip, for slider area which is unavailable
                            Item
                            {
                                function showTooltip (showTooltip)
                                {
                                    if (showTooltip)
                                    {
                                        var content = catalog.i18nc("@tooltip", "This quality profile is not available for you current material and nozzle configuration. Please change these to enable this quality profile")
                                        base.showTooltip(qualityRow, Qt.point(-UM.Theme.getSize("sidebar_margin").width, customisedSettings.height), content)
                                    }
                                    else
                                    {
                                        base.hideTooltip()
                                    }
                                }

                                id: unavailableLineToolTip
                                height: 20 * screenScaleFactor // hovered area height
                                z: parent.z + 1 // should be higher, otherwise the area can be hovered
                                x: 0
                                anchors.verticalCenter: qualitySlider.verticalCenter

                                Rectangle
                                {
                                    id: leftArea
                                    width:
                                    {
                                        if (qualityModel.availableTotalTicks == 0)
                                        {
                                            return qualityModel.qualitySliderStepWidth * qualityModel.totalTicks
                                        }
                                        return qualityModel.qualitySliderStepWidth * qualityModel.qualitySliderAvailableMin - 10
                                    }
                                    height: parent.height
                                    color: "transparent"

                                    MouseArea
                                    {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: Cura.SimpleModeSettingsManager.isProfileUserCreated == false
                                        onEntered: unavailableLineToolTip.showTooltip(true)
                                        onExited: unavailableLineToolTip.showTooltip(false)
                                    }
                                }

                                Rectangle
                                {
                                    id: rightArea
                                    width:
                                    {
                                        if(qualityModel.availableTotalTicks == 0)
                                            return 0

                                        return qualityModel.qualitySliderMarginRight - 10
                                    }
                                    height: parent.height
                                    color: "transparent"
                                    x:
                                    {
                                        if (qualityModel.availableTotalTicks == 0)
                                        {
                                            return 0
                                        }

                                        var leftUnavailableArea = qualityModel.qualitySliderStepWidth * qualityModel.qualitySliderAvailableMin
                                        var totalGap = qualityModel.qualitySliderStepWidth * (qualityModel.availableTotalTicks -1) + leftUnavailableArea + 10

                                        return totalGap
                                    }

                                    MouseArea
                                    {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: Cura.SimpleModeSettingsManager.isProfileUserCreated == false
                                        onEntered: unavailableLineToolTip.showTooltip(true)
                                        onExited: unavailableLineToolTip.showTooltip(false)
                                    }
                                }
                            }

                            // Draw Unavailable line
                            Rectangle
                            {
                                id: groovechildrect
                                width: Math.round(base.width * 0.55)
                                height: 2 * screenScaleFactor
                                color: UM.Theme.getColor("quality_slider_unavailable")
                                anchors.verticalCenter: qualitySlider.verticalCenter
                                x: 0
                            }

                            // Draw ticks
                            Repeater
                            {
                                id: qualityRepeater
                                model: qualityModel.totalTicks > 0 ? qualityModel : 0

                                Rectangle
                                {
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Cura.QualityProfilesDropDownMenuModel.getItem(index).available ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                    width: 1 * screenScaleFactor
                                    height: 6 * screenScaleFactor
                                    y: 0
                                    x: Math.round(qualityModel.qualitySliderStepWidth * index)
                                }
                            }

                            Slider
                            {
                                id: qualitySlider
                                height: UM.Theme.getSize("sidebar_margin").height
                                anchors.bottom: speedSlider.bottom
                                enabled: qualityModel.totalTicks > 0 && !Cura.SimpleModeSettingsManager.isProfileCustomized
                                visible: qualityModel.availableTotalTicks > 0
                                updateValueWhileDragging : false

                                minimumValue: qualityModel.qualitySliderAvailableMin >= 0 ? qualityModel.qualitySliderAvailableMin : 0
                                // maximumValue must be greater than minimumValue to be able to see the handle. While the value is strictly
                                // speaking not always correct, it seems to have the correct behavior (switching from 0 available to 1 available)
                                maximumValue: qualityModel.qualitySliderAvailableMax >= 1 ? qualityModel.qualitySliderAvailableMax : 1
                                stepSize: 1

                                value: qualityModel.qualitySliderActiveIndex

                                width: qualityModel.qualitySliderStepWidth * (qualityModel.availableTotalTicks - 1)

                                anchors.right: parent.right
                                anchors.rightMargin: qualityModel.qualitySliderMarginRight

                                style: SliderStyle
                                {
                                    //Draw Available line
                                    groove: Rectangle
                                    {
                                        implicitHeight: 2 * screenScaleFactor
                                        color: UM.Theme.getColor("quality_slider_available")
                                        radius: Math.round(height / 2)
                                    }
                                    handle: Item
                                    {
                                        Rectangle
                                        {
                                            id: qualityhandleButton
                                            anchors.centerIn: parent
                                            color: UM.Theme.getColor("quality_slider_available")
                                            implicitWidth: 10 * screenScaleFactor
                                            implicitHeight: implicitWidth
                                            radius: Math.round(implicitWidth / 2)
                                            visible: !Cura.SimpleModeSettingsManager.isProfileCustomized && !Cura.SimpleModeSettingsManager.isProfileUserCreated && qualityModel.existingQualityProfile
                                        }
                                    }
                                }

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
                            }

                            MouseArea
                            {
                                id: speedSliderMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: Cura.SimpleModeSettingsManager.isProfileUserCreated

                                onEntered:
                                {
                                    var content = catalog.i18nc("@tooltip","A custom profile is currently active. To enable the quality slider, choose a default quality profile in Custom tab")
                                    base.showTooltip(qualityRow, Qt.point(-UM.Theme.getSize("sidebar_margin").width, customisedSettings.height),  content)
                                }
                                onExited:
                                {
                                    base.hideTooltip();
                                }
                            }
                        }

                        Label
                        {
                            id: speedLabel
                            anchors {
                                top: speedSlider.bottom; left: parent.left
                                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }

                            text: catalog.i18nc("@label", "Print Speed")
                            font: UM.Theme.getFont("default")
                            color: UM.Theme.getColor("text_sidebar")
                            width: Math.round(UM.Theme.getSize("sidebar").width * 0.35)
                            elide: Text.ElideRight
                        }

                        Label
                        {
                            anchors.bottom: speedLabel.bottom
                            anchors.left: speedSlider.left

                            text: catalog.i18nc("@label", "Slower")
                            font: UM.Theme.getFont("default")
                            color: (qualityModel.availableTotalTicks > 1) ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                            horizontalAlignment: Text.AlignLeft
                        }

                        Label
                        {
                            anchors.bottom: speedLabel.bottom
                            anchors.right: speedSlider.right

                            text: catalog.i18nc("@label", "Faster")
                            font: UM.Theme.getFont("default")
                            color: (qualityModel.availableTotalTicks > 1) ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                            horizontalAlignment: Text.AlignRight
                        }

                        UM.SimpleButton
                        {
                            id: customisedSettings

                            visible: Cura.SimpleModeSettingsManager.isProfileCustomized || Cura.SimpleModeSettingsManager.isProfileUserCreated
                            height: Math.round(speedSlider.height * 0.8)
                            width: Math.round(speedSlider.height * 0.8)

                            anchors.verticalCenter: speedSlider.verticalCenter
                            anchors.right: speedSlider.left
                            anchors.rightMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2)

                            color: hovered ? UM.Theme.getColor("setting_control_button_hover") : UM.Theme.getColor("setting_control_button");
                            iconSource: UM.Theme.getIcon("reset");

                            onClicked:
                            {
                                // if the current profile is user-created, switch to a built-in quality
                                Cura.MachineManager.resetToUseDefaultQuality()
                            }
                            onEntered:
                            {
                                var content = catalog.i18nc("@tooltip","You have modified some profile settings. If you want to change these go to custom mode.")
                                base.showTooltip(qualityRow, Qt.point(-UM.Theme.getSize("sidebar_margin").width, customisedSettings.height),  content)
                            }
                            onExited: base.hideTooltip()
                        }
                    }
                }
            }



            //
            // Infill
            //
            Item
            {
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 125
                Layout.alignment: Qt.AlignHCenter

                // Background
                RectangularGlow {

                    anchors.fill: parent
                    glowRadius: 3
                    spread: 0
                    color: UM.Theme.getColor("sidebar_item_glow")
                    cornerRadius: 2

                    Rectangle {
                        anchors.fill: parent
                        color: UM.Theme.getColor("sidebar_item")
                        radius: 2
                        width: parent.width
                        Item
                        {
                            id: infillCellLeft

                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom

                            width: Math.round(base.width * .35)

                            Label
                            {
                                id: infillLabel
                                text: "Fill density" //catalog.i18nc("@label", "Infill")
                                font: UM.Theme.getFont("default_bold");
                                color: UM.Theme.getColor("text_sidebar")

                                anchors.top: parent.top
                                anchors.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                                anchors.left: parent.left
                                anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                            }
                            Rectangle
                            {
                                id: infillIcon

                                width: 60
                                height: width

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
                                        border.color: UM.Theme.getColor("quality_slider_unavailable")

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
                            Label
                            {
                                id: selectedInfillRateText

                                anchors.top: infillIcon.bottom
                                anchors.topMargin: 3
                                anchors.left: parent.left
                                anchors.leftMargin: 50
                                font: UM.Theme.getFont("extra_small")

                                text: parseInt(infillDensity.properties.value) + "%"

                                color: infillSlider.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                            }
                        }

                        Item
                        {
                            id: infillCellRight

                            width: Math.round(base.width * .55)
                            height: infillCellLeft.height

                            anchors.left: infillCellLeft.right
                            anchors.bottom: infillCellLeft.bottom
                            anchors.bottomMargin: UM.Theme.getSize("sidebar_item_margin").height * 2

                            // We use a binding to make sure that after manually setting infillSlider.value it is still bound to the property provider
                            Binding {
                                target: infillSlider
                                property: "value"
                                value: parseInt(infillDensity.properties.value)
                            }

                            Slider
                            {
                                id: infillSlider

                                anchors.bottom: parent.bottom
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

                                    // Update value only if the Recomended mode is Active,
                                    // Otherwise if I change the value in the Custom mode the Recomended view will try to repeat
                                    // same operation
                                    var active_mode = UM.Preferences.getValue("cura/active_mode")

                                    if (active_mode == 0 || active_mode == "simple")
                                    {
                                        Cura.MachineManager.setSettingForAllExtruders("infill_sparse_density", "value", roundedSliderValue)
                                        Cura.MachineManager.resetSettingForAllExtruders("infill_line_distance")
                                    }
                                }

                                style: SliderStyle
                                {
                                    groove: Rectangle {
                                        id: groove
                                        implicitWidth: 200 * screenScaleFactor
                                        implicitHeight: 10 * screenScaleFactor
                                        color: control.enabled ? UM.Theme.getColor("quality_slider_available") : UM.Theme.getColor("quality_slider_unavailable")
                                        radius: 4
                                    }

                                    handle: Item {
                                        Rectangle {
                                            id: handleButton
                                            anchors.centerIn: parent
                                            color: control.enabled ? UM.Theme.getColor("quality_slider_handle") : UM.Theme.getColor("quality_slider_unavailable")
                                            implicitWidth: 20 * screenScaleFactor
                                            implicitHeight: 20 * screenScaleFactor
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
            }
            Item {
                Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
                Layout.preferredHeight: 100
                Layout.alignment: Qt.AlignHCenter

                Button {
                    id: sliceButton
                    anchors.right: parent.right
                    width: 75; height: 35
                    onClicked:
                    {
                        CuraApplication.backend.forceSlice();
                        UM.Controller.setActiveStage("NetworkMachineList")
                        UM.Controller.setActiveView("SimulationView")
                    }
                    style: ButtonStyle {
                        background: Rectangle
                        {
                            border.width: UM.Theme.getSize("default_lining").width
                            border.color:
                            {
                                if(!control.enabled)
                                    return UM.Theme.getColor("sidebar_action_button_disabled_border");
                                else if(control.pressed)
                                    return UM.Theme.getColor("sidebar_action_button_active_border");
                                else if(control.hovered)
                                    return UM.Theme.getColor("sidebar_action_button_hovered_border");
                                else
                                    return UM.Theme.getColor("sidebar_action_button_border");
                            }
                            color:
                            {
                                if(!control.enabled)
                                    return UM.Theme.getColor("sidebar_action_button_disabled");
                                else if(control.pressed)
                                    return UM.Theme.getColor("sidebar_action_button_active");
                                else if(control.hovered)
                                    return UM.Theme.getColor("sidebar_action_button_hovered");
                                else
                                    return UM.Theme.getColor("sidebar_action_button");
                            }

                            Label {
                                color: "white"
                                width: 75; height: 35
                                text: "Slice!"
                                font { pointSize: 15 }
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                        }
                    }
                }
                Button {
                    id: cancelButton
                    anchors.right: sliceButton.left
                    anchors.rightMargin: 2
                    width: 75; height: 35
                    onClicked:
                    {
                        CuraApplication.backend.stopSlicing();
                        UM.Controller.setActiveStage("NetworkMachineList")
                    }
                    style: ButtonStyle {
                        background: Rectangle
                        {
                            radius: 2
                            border.width: UM.Theme.getSize("default_lining").width
                            border.color:
                            {
                                if(!control.enabled)
                                    return UM.Theme.getColor("sidebar_action_button_disabled_border");
                                else if(control.pressed)
                                    return UM.Theme.getColor("sidebar_action_button_active_border");
                                else if(control.hovered)
                                    return UM.Theme.getColor("sidebar_action_button_hovered_border");
                                else
                                    return UM.Theme.getColor("sidebar_action_button_border");
                            }
                            color:
                            {
                                if(!control.enabled)
                                    return UM.Theme.getColor("sidebar_action_button_disabled");
                                else if(control.pressed)
                                    return UM.Theme.getColor("sidebar_action_button_active");
                                else if(control.hovered)
                                    return UM.Theme.getColor("sidebar_action_button_hovered");
                                else
                                    return UM.Theme.getColor("sidebar_action_button");
                            }

                            Label {
                                color: "white"
                                width: 75; height: 35
                                text: "Cancel"
                                font { pointSize: 15 }
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
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

    function populateExtruderModel()
    {
        extruderModel.clear();
        for(var extruderNumber = 0; extruderNumber < extruders.rowCount() ; extruderNumber++)
        {
            extruderModel.append({
                text: extruders.getItem(extruderNumber).name,
                color: extruders.getItem(extruderNumber).color
            })
        }
        supportExtruderCombobox.updateCurrentColor();
    }
}
