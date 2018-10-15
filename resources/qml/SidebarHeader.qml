// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtGraphicalEffects 1.0

import UM 1.2 as UM
import Cura 1.0 as Cura

import "Menus"

Column
{
    id: base;

    property int currentExtruderIndex: Cura.ExtruderManager.activeExtruderIndex;
    spacing: Math.round(UM.Theme.getSize("sidebar_margin").width * 0.9)

    signal showTooltip(Item item, point location, string text)
    signal hideTooltip()

   Rectangle {
        id: headerSeparator
        width: parent.width
        height: UM.Theme.getSize("sidebar_lining").height
        color: UM.Theme.getColor("sidebar_lining")
    }

    Rectangle {
        height: UM.Theme.getSize("setting_control").height
        width: parent.width - ((UM.Theme.getSize("sidebar_item_margin").width + UM.Theme.getSize("sidebar_margin").width) * 2)
        color: UM.Theme.getColor("sidebar")
        anchors.left: parent.left
        anchors.leftMargin: UM.Theme.getSize("sidebar_margin").width + UM.Theme.getSize("sidebar_item_margin").width
        anchors.rightMargin: UM.Theme.getSize("sidebar_margin").width + UM.Theme.getSize("sidebar_item_margin").width
        Label
        {
            id: titleLabel
            text: "Prepare to print"
            width: parent.width - UM.Theme.getSize("default_margin").width
            anchors.leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            font: UM.Theme.getFont("extra_large");
            color: UM.Theme.getColor("text_sidebar");
        }
        Rectangle {
            id: titleSeparator
            width: parent.width
            anchors.top: titleLabel.bottom
            height: UM.Theme.getSize("sidebar_lining_extra_thin").height
            color: UM.Theme.getColor("sidebar_lining_extra_thin")
        }
    }


    // Background
    RectangularGlow {
        id: effect
        height: UM.Theme.getSize("sidebar_setup").height

        anchors
        {
            left: parent.left
            leftMargin: UM.Theme.getSize("sidebar_margin").width
            right: parent.right
            rightMargin: UM.Theme.getSize("sidebar_margin").width
        }
        glowRadius: 3
        spread: 0
        color: UM.Theme.getColor("sidebar_item_glow")
        cornerRadius: rect.radius

        Rectangle {
            id: rect
            anchors.fill: parent
            color: UM.Theme.getColor("sidebar_item")
            radius: 2
            width: parent.width
            // Material Row
            Item
            {
                id: materialRow
                anchors {
                    fill: parent
                    leftMargin: UM.Theme.getSize("sidebar_item_margin").width
                    topMargin: UM.Theme.getSize("sidebar_item_margin").height
                }

                Label
                {
                    id: materialLabel
                    text: catalog.i18nc("@label", "Material");
                    width: parent.width - UM.Theme.getSize("default_margin").width
                    height: UM.Theme.getSize("setting_control").height
                    verticalAlignment: Text.AlignVCenter
                    font: UM.Theme.getFont("default_bold");
                    color: UM.Theme.getColor("text_sidebar");
                }

                ToolButton
                {
                    id: materialSelection

                    property var activeExtruder: Cura.MachineManager.activeStack
                    property var hasActiveExtruder: activeExtruder != null
                    property var currentRootMaterialName: hasActiveExtruder ? activeExtruder.material.name : ""

                    text: currentRootMaterialName
                    tooltip: currentRootMaterialName
                    visible: Cura.MachineManager.hasMaterials
                    enabled: base.currentExtruderIndex > -1
                    height: UM.Theme.getSize("setting_control").height
                    width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
                    anchors.top: materialLabel.bottom
                    style: UM.Theme.styles.sidebar_header_button
                    activeFocusOnPress: true;
                    menu: MaterialMenu
                    {
                        extruderIndex: base.currentExtruderIndex
                    }
                }
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStack: Cura.MachineManager.activeMachine
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
        storeIndex: 0
    }

    UM.I18nCatalog { id: catalog; name:"cura" }
}
