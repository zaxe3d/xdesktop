// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.4 as UM
import Cura 1.0 as Cura
import "Menus"

Rectangle
{
    id: base
    anchors.left: parent.left
    anchors.right: parent.right
    height: UM.Theme.getSize("sidebar_header").height
    color:  UM.Theme.getColor("topbar_background_color")

    property bool printerConnected: Cura.MachineManager.printerConnected
    property bool printerAcceptsCommands: printerConnected && Cura.MachineManager.printerOutputDevices[0].acceptsCommands

    property int rightMargin: UM.Theme.getSize("sidebar").width + UM.Theme.getSize("default_margin").width;
    property int allItemsWidth: 0;

    function updateMarginsAndSizes() {
        if (UM.Preferences.getValue("cura/sidebar_collapsed"))
        {
            rightMargin = UM.Theme.getSize("default_margin").width;
        }
        else
        {
            rightMargin = UM.Theme.getSize("sidebar").width + UM.Theme.getSize("default_margin").width;
        }
        allItemsWidth = (
            UM.Theme.getSize("default_margin").width + viewModeButton.width +
            rightMargin);
    }

    UM.I18nCatalog
    {
        id: catalog
        name:"cura"
    }

    // View orientation Item
    Row
    {
        id: viewOrientationControl
        height: 30

        spacing: 2 

        anchors
        {
            verticalCenter: base.verticalCenter
            right: viewModeButton.left
            rightMargin: UM.Theme.getSize("default_margin").width
        }

        // #1 3d view
        Button
        {
            iconSource: UM.Theme.getIcon("view_3d")
            style: UM.Theme.styles.small_tool_button
            anchors.verticalCenter: viewOrientationControl.verticalCenter
            onClicked:UM.Controller.rotateView("3d", 0)
            visible: base.width - allItemsWidth - 4 * this.width > 0
        }

        // #2 Front view
        Button
        {
            iconSource: UM.Theme.getIcon("view_front")
            style: UM.Theme.styles.small_tool_button
            anchors.verticalCenter: viewOrientationControl.verticalCenter
            onClicked: UM.Controller.rotateView("home", 0);
            visible: base.width - allItemsWidth - 3 * this.width > 0
        }

        // #3 Top view
        Button
        {
            iconSource: UM.Theme.getIcon("view_top")
            style: UM.Theme.styles.small_tool_button
            anchors.verticalCenter: viewOrientationControl.verticalCenter
            onClicked: UM.Controller.rotateView("y", 90)
            visible: base.width - allItemsWidth - 2 * this.width > 0
        }

        // #4 Left view
        Button
        {
            iconSource: UM.Theme.getIcon("view_left")
            style: UM.Theme.styles.small_tool_button
            anchors.verticalCenter: viewOrientationControl.verticalCenter
            onClicked: UM.Controller.rotateView("x", 90)
            visible: base.width - allItemsWidth - 1 * this.width > 0
        }

        // #5 Right view
        Button
        {
            iconSource: UM.Theme.getIcon("view_right")
            style: UM.Theme.styles.small_tool_button
            anchors.verticalCenter: viewOrientationControl.verticalCenter
            onClicked: UM.Controller.rotateView("x", -90)
            visible: base.width - allItemsWidth > 0
        }
    }

    ComboBox
    {
        id: viewModeButton

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: rightMargin
        }

        style: UM.Theme.styles.combobox
        visible: UM.Controller.activeStage.stageId != "MonitorStage"

        model: UM.ViewModel { }
        textRole: "name"

        // update the model's active index
        function updateItemActiveFlags () {
            currentIndex = getActiveIndex()
            for (var i = 0; i < model.rowCount(); i++) {
                model.getItem(i).active = (i == currentIndex)
            }
        }

        // get the index of the active model item on start
        function getActiveIndex () {
            for (var i = 0; i < model.rowCount(); i++) {
                if (model.getItem(i).active) {
                    return i
                }
            }
            return 0
        }

        // set the active index
        function setActiveIndex (index) {
            UM.Controller.setActiveView(index)
            // the connection to UM.ActiveView will trigger update so there is no reason to call it manually here
        }

        onCurrentIndexChanged:
        {
            if (model.getItem(currentIndex).id != undefined)
                viewModeButton.setActiveIndex(model.getItem(currentIndex).id)
        }
        currentIndex: getActiveIndex()

        // watch the active view proxy for changes made from the menu item
        Connections
        {
            target: UM.ActiveView
            onActiveViewChanged: viewModeButton.updateItemActiveFlags()
        }
    }

    Loader
    {
        id: view_panel

        anchors.top: viewModeButton.bottom
        anchors.topMargin: UM.Theme.getSize("default_margin").height
        anchors.right: viewModeButton.right

        property var buttonTarget: Qt.point(viewModeButton.x + Math.round(viewModeButton.width / 2), viewModeButton.y + Math.round(viewModeButton.height / 2))

        height: childrenRect.height
        width: childrenRect.width

        source: UM.ActiveView.valid ? UM.ActiveView.activeViewPanel : "";
    }

    // Expand or collapse sidebar
    Connections
    {
        target: Cura.Actions.expandSidebar
        onTriggered: updateMarginsAndSizes()
    }

    Component.onCompleted:
    {
        updateMarginsAndSizes();
    }

}
