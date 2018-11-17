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
            logo.width + UM.Theme.getSize("topbar_logo_right_margin").width +
            UM.Theme.getSize("default_margin").width + viewModeButton.width +
            rightMargin);
    }

    UM.I18nCatalog
    {
        id: catalog
        name:"cura"
    }

    Image
    {
        id: logo
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 30
        anchors.leftMargin: Math.round(UM.Theme.getSize("toolbar").width / 2 - UM.Theme.getSize("logo").width / 2)

        source: UM.Theme.getImage("logo");
        width: UM.Theme.getSize("logo").width;
        height: UM.Theme.getSize("logo").height;

        sourceSize.width: width;
        sourceSize.height: height;
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                extensionOpacityAnimator.stop()
                extensionOpacityAnimator.from = 0
                extensionOpacityAnimator.to = 1
                extensionOpacityAnimator.start()
            }
            onExited: {
                extensionOpacityAnimator.stop()
                extensionOpacityAnimator.from = 1
                extensionOpacityAnimator.to = 0
                extensionOpacityAnimator.start()
            }
        }
        OpacityAnimator {
            id: extensionOpacityAnimator
            target: logoExtension
            from: 0
            to: 1
            duration: 1000
            running: false
        }
    }

    Image
    {
        id: logoExtension
        opacity: 0

        anchors {
            left: logo.right
            top: parent.top
            topMargin: 23
            leftMargin: 8
        }


        source: UM.Theme.getImage("desktop");
        width: UM.Theme.getSize("desktop").width;
        height: UM.Theme.getSize("desktop").height;

        sourceSize.width: width;
        sourceSize.height: height;
    }

    // Bottom Border
    Rectangle { id: logoBorder; anchors { top: logo.bottom; topMargin: 20; left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }


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
