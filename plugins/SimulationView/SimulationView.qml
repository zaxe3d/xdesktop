// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.1

import UM 1.0 as UM
import Cura 1.0 as Cura

Item
{
    id: base
    width:
    {
        if (UM.SimulationView.compatibilityMode)
        {
            return UM.Theme.getSize("layerview_menu_size_compatibility").width;
        }
        else
        {
            return UM.Theme.getSize("layerview_menu_size").width;
        }
    }
    height: {
        if (viewSettings.collapsed)
        {
            if (UM.SimulationView.compatibilityMode)
            {
                return UM.Theme.getSize("layerview_menu_size_compatibility_collapsed").height;
            }
            return UM.Theme.getSize("layerview_menu_size_collapsed").height;
        }
        else if (UM.SimulationView.compatibilityMode)
        {
            return UM.Theme.getSize("layerview_menu_size_compatibility").height;
        }
        else if (UM.Preferences.getValue("layerview/layer_view_type") == 0)
        {
            return UM.Theme.getSize("layerview_menu_size_material_color_mode").height + UM.SimulationView.extruderCount * (UM.Theme.getSize("layerview_row").height + UM.Theme.getSize("layerview_row_spacing").height)
        }
        else
        {
            return UM.Theme.getSize("layerview_menu_size").height + UM.SimulationView.extruderCount * (UM.Theme.getSize("layerview_row").height + UM.Theme.getSize("layerview_row_spacing").height)
        }
    }
    Behavior on height { NumberAnimation { duration: 100 } }

    property var buttonTarget:
    {
        if(parent != null)
        {
            var force_binding = parent.y; // ensure this gets reevaluated when the panel moves
            return base.mapFromItem(parent.parent, parent.buttonTarget.x, parent.buttonTarget.y)
        }
        return Qt.point(0,0)
    }

    Item
    {
        id: slidersBox

        width: parent.width
        visible: UM.SimulationView.layerActivity && CuraApplication.platformActivity

        anchors
        {
            bottom: parent.bottom
            topMargin: UM.Theme.getSize("slider_layerview_margin").height
            left: parent.left
        }

        PathSlider
        {
            id: pathSlider

            height: UM.Theme.getSize("slider_handle").width
            anchors.left: playButton.right
            anchors.leftMargin: UM.Theme.getSize("default_margin").width
            anchors.right: parent.right
            visible: !UM.SimulationView.compatibilityMode

            // custom properties
            handleValue: UM.SimulationView.currentPath
            maximumValue: UM.SimulationView.numPaths
            handleSize: UM.Theme.getSize("slider_handle").width
            trackThickness: UM.Theme.getSize("slider_groove").width
            trackColor: UM.Theme.getColor("slider_groove")
            trackBorderColor: UM.Theme.getColor("slider_groove_border")
            handleColor: UM.Theme.getColor("slider_handle")
            handleActiveColor: UM.Theme.getColor("slider_handle_active")
            rangeColor: UM.Theme.getColor("slider_groove_fill")

            // update values when layer data changes
            Connections
            {
                target: UM.SimulationView
                onMaxPathsChanged: pathSlider.setHandleValue(UM.SimulationView.currentPath)
                onCurrentPathChanged:
                {
                    // Only pause the simulation when the layer was changed manually, not when the simulation is running
                    if (pathSlider.manuallyChanged)
                    {
                        playButton.pauseSimulation()
                    }
                    pathSlider.setHandleValue(UM.SimulationView.currentPath)
                }
            }

            // make sure the slider handlers show the correct value after switching views
            Component.onCompleted:
            {
                pathSlider.setHandleValue(UM.SimulationView.currentPath)
            }
        }

        LayerSlider
        {
            id: layerSlider

            width: UM.Theme.getSize("slider_handle").width
            height: UM.Theme.getSize("layerview_menu_size").height

            anchors
            {
                top: !UM.SimulationView.compatibilityMode ? pathSlider.bottom : parent.top
                topMargin: !UM.SimulationView.compatibilityMode ? UM.Theme.getSize("default_margin").height : 0
                right: parent.right
                rightMargin: UM.Theme.getSize("slider_layerview_margin").width
            }

            // custom properties
            upperValue: UM.SimulationView.currentLayer
            lowerValue: UM.SimulationView.minimumLayer
            maximumValue: UM.SimulationView.numLayers
            handleSize: UM.Theme.getSize("slider_handle").width
            trackThickness: UM.Theme.getSize("slider_groove").width
            trackColor: UM.Theme.getColor("slider_groove")
            trackBorderColor: UM.Theme.getColor("slider_groove_border")
            upperHandleColor: UM.Theme.getColor("slider_handle")
            lowerHandleColor: UM.Theme.getColor("slider_handle")
            rangeHandleColor: UM.Theme.getColor("slider_groove_fill")
            handleActiveColor: UM.Theme.getColor("slider_handle_active")
            handleLabelWidth: UM.Theme.getSize("slider_layerview_background").width

            // update values when layer data changes
            Connections
            {
                target: UM.SimulationView
                onMaxLayersChanged: layerSlider.setUpperValue(UM.SimulationView.currentLayer)
                onMinimumLayerChanged: layerSlider.setLowerValue(UM.SimulationView.minimumLayer)
                onCurrentLayerChanged:
                {
                    // Only pause the simulation when the layer was changed manually, not when the simulation is running
                    if (layerSlider.manuallyChanged)
                    {
                        playButton.pauseSimulation()
                    }
                    layerSlider.setUpperValue(UM.SimulationView.currentLayer)
                }
            }

            // make sure the slider handlers show the correct value after switching views
            Component.onCompleted:
            {
                layerSlider.setLowerValue(UM.SimulationView.minimumLayer)
                layerSlider.setUpperValue(UM.SimulationView.currentLayer)
            }
        }

        // Play simulation button
        Button
        {
            id: playButton
            iconSource: "./resources/simulation_resume.svg"
            style: UM.Theme.styles.small_tool_button
            visible: !UM.SimulationView.compatibilityMode
            anchors
            {
                verticalCenter: pathSlider.verticalCenter
            }

            property var status: 0  // indicates if it's stopped (0) or playing (1)

            onClicked:
            {
                switch(status)
                {
                    case 0:
                    {
                        resumeSimulation()
                        break
                    }
                    case 1:
                    {
                        pauseSimulation()
                        break
                    }
                }
            }

            function pauseSimulation()
            {
                UM.SimulationView.setSimulationRunning(false)
                iconSource = "./resources/simulation_resume.svg"
                simulationTimer.stop()
                status = 0
                layerSlider.manuallyChanged = true
                pathSlider.manuallyChanged = true
            }

            function resumeSimulation()
            {
                UM.SimulationView.setSimulationRunning(true)
                iconSource = "./resources/simulation_pause.svg"
                simulationTimer.start()
                layerSlider.manuallyChanged = false
                pathSlider.manuallyChanged = false
            }
            Shortcut {
                sequence: StandardKey.Bold
                context: Qt.ApplicationShortcut
                onActivated: playButton.clicked()
            }

        }

        Timer
        {
            id: simulationTimer
            interval: 100
            running: false
            repeat: true
            onTriggered:
            {
                var currentPath = UM.SimulationView.currentPath
                var numPaths = UM.SimulationView.numPaths
                var currentLayer = UM.SimulationView.currentLayer
                var numLayers = UM.SimulationView.numLayers
                // When the user plays the simulation, if the path slider is at the end of this layer, we start
                // the simulation at the beginning of the current layer.
                if (playButton.status == 0)
                {
                    if (currentPath >= numPaths)
                    {
                        UM.SimulationView.setCurrentPath(0)
                    }
                    else
                    {
                        UM.SimulationView.setCurrentPath(currentPath+1)
                    }
                }
                // If the simulation is already playing and we reach the end of a layer, then it automatically
                // starts at the beginning of the next layer.
                else
                {
                    if (currentPath >= numPaths)
                    {
                        // At the end of the model, the simulation stops
                        if (currentLayer >= numLayers)
                        {
                            playButton.pauseSimulation()
                        }
                        else
                        {
                            UM.SimulationView.setCurrentLayer(currentLayer+1)
                            UM.SimulationView.setCurrentPath(0)
                        }
                    }
                    else
                    {
                        UM.SimulationView.setCurrentPath(currentPath+1)
                    }
                }
                // The status must be set here instead of in the resumeSimulation function otherwise it won't work
                // correctly, because part of the logic is in this trigger function.
                playButton.status = 1
            }
        }
    }

    FontMetrics
    {
        id: fontMetrics
        font: UM.Theme.getFont("default")
    }
}
