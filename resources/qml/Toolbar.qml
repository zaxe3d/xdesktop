// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: toolbar;

    width: buttons.width;
    height: buttons.height
    property int activeY

    Column
    {
        id: buttons;

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        spacing: UM.Theme.getSize("button_lining").width

        z: 5

        Repeater
        {
            id: repeat

            model: UM.ToolModel { }
            width: childrenRect.width
            height: childrenRect.height
            Column
            {
                Button
                {
                    text: model.name + (model.shortcut ? (" (" + model.shortcut + ")") : "")
                    anchors { left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) }
                    property string iconText: model.iconText
                    checkable: true
                    checked: model.active
                    enabled: model.enabled && UM.Selection.hasSelection && UM.Controller.toolsEnabled
                    style: UM.Theme.styles.tool_button

                    onCheckedChanged:
                    {
                        if (checked)
                        {
                            toolbar.activeY = parent.y;
                        }
                    }

                    //Workaround since using ToolButton's onClicked would break the binding of the checked property, instead
                    //just catch the click so we do not trigger that behaviour.
                    MouseArea
                    {
                        anchors.fill: parent;
                        onClicked:
                        {
                            forceActiveFocus() //First grab focus, so all the text fields are updated
                            if(parent.checked)
                            {
                                UM.Controller.setActiveTool(null);
                            }
                            else
                            {
                                UM.Controller.setActiveTool(model.id);
                            }
                        }
                    }
                }
                // Bottom Border
                Rectangle { anchors { left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: UM.Theme.getSize("toolbar_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }
            }
        }

        Item { height: UM.Theme.getSize("default_margin").height; width: UM.Theme.getSize("default_lining").width; visible: extruders.count > 0 }

        Repeater
        {
            id: extruders
            width: childrenRect.width
            height: childrenRect.height
            property var _model: Cura.ExtrudersModel { id: extrudersModel }
            model: _model.items.length > 1 ? _model : 0
            ExtruderButton { extruder: model }
        }
    }

    UM.PointingRectangle
    {
        id: panelBorder;

        anchors {
            left: parent.left
            leftMargin: toolbar.marginL + 1
            top: toolbar.top;
            topMargin: toolbar.activeY
        }

        target: Qt.point(parent.right, toolbar.activeY +  Math.round(UM.Theme.getSize("button").height/2))
        arrowSize: 0

        width:
        {
            if (panel.item && panel.width > 0)
            {
                 return Math.max(panel.width + 2 * UM.Theme.getSize("default_margin").width);
            }
            else
            {
                return 0;
            }
        }
        height: panel.item ? panel.height + 2.5 * UM.Theme.getSize("default_margin").height : 0;

        opacity: panel.item && panel.width > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        color: UM.Theme.getColor("tool_panel_background")
        borderColor: UM.Theme.getColor("lining")
        borderWidth: UM.Theme.getSize("default_lining").width

        MouseArea //Catch all mouse events (so scene doesnt handle them)
        {
            anchors.fill: parent
        }

        Loader
        {
            id: panel

            x: UM.Theme.getSize("default_margin").width;
            y: UM.Theme.getSize("default_margin").height;

            source: UM.ActiveTool.valid ? UM.ActiveTool.activeToolPanel : ""
            enabled: UM.Controller.toolsEnabled;
        }
    }

    // This rectangle displays the information about the current angle etc. when
    // dragging a tool handle.
    Rectangle
    {
        x: -toolbar.x + toolbar.mouseX + UM.Theme.getSize("default_margin").width
        y: -toolbar.y + toolbar.mouseY + UM.Theme.getSize("default_margin").height

        width: toolHint.width + UM.Theme.getSize("default_margin").width
        height: toolHint.height;
        color: UM.Theme.getColor("tooltip")
        Label
        {
            id: toolHint
            text: UM.ActiveTool.properties.getValue("ToolHint") != undefined ? UM.ActiveTool.properties.getValue("ToolHint") : ""
            color: UM.Theme.getColor("tooltip_text")
            font: UM.Theme.getFont("default")
            anchors.horizontalCenter: parent.horizontalCenter
        }

        visible: toolHint.text != ""
    }

}
