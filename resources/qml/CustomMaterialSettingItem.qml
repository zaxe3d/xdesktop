import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: item

    property string label             // label of the setting
    property string type              // type of the setting ie: int, float
    property string unit              // unit next to item
    property string profileIdx        // idx of the profile it belongs to
    property string preferenceId      // id of the prefrence to set
    property string extraPreferenceId // another id of the prefrence to set
    property var extraFunc            // extra function to be executed when setting val
    property string valStr: "custom_material_profile/" + profileIdx + "_" + preferenceId

    property var validator

    Layout.preferredWidth: parent.width - (UM.Theme.getSize("sidebar_margin").width * 2)
    Layout.preferredHeight: 40
    Layout.alignment: Qt.AlignLeft

    Rectangle {
        anchors {
            fill: parent
            leftMargin: UM.Theme.getSize("sidebar_item_margin").width
        }
        color: UM.Theme.getColor("sidebar_item_light")

        Item
        {
            id: settingItemCellLeft

            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
            width: Math.round(base.width * .69)

            Label
            {
                id: settingItemLabel
                text: item.label
                font: UM.Theme.getFont("medium");
                color: UM.Theme.getColor("text_sidebar")

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }
            Label
            {
                id: settingItemInfoLabel
                text: "(" + item.validator.bottom + "-" + item.validator.top + " " + item.unit + ")"
                font: UM.Theme.getFont("small");
                color: UM.Theme.getColor("text_sidebar_medium")

                anchors {
                    left: settingItemLabel.right
                    leftMargin: 5
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        Item
        {
            width: Math.round(base.width * .22)
            height: settingItemCellLeft.height

            anchors.left: settingItemCellLeft.right
            anchors.bottom: settingItemCellLeft.bottom


            TextField {
                width: parent.width
                height: UM.Theme.getSize("setting_control").height
                anchors.verticalCenter: parent.verticalCenter
                style: UM.Theme.styles.text_field

                validator: item.validator
                property string unit: item.unit
                property var value:
                {
                    switch(item.type) {
                    case "int": return parseInt(text)
                    case "float": return parseFloat(text)
                    }
                }

                text: {
                    switch(item.type) {
                    case "int": return parseInt(Number.fromLocaleString(Qt.locale(), UM.Preferences.getValue(valStr)));
                    case "float": return parseFloat(Number.fromLocaleString(Qt.locale(), UM.Preferences.getValue(valStr)));
                    }
                }

                onEditingFinished:
                {
                    if (!acceptableInput) return // no need to to anything if not acceptable
                    UM.Preferences.setValue(valStr, value) // set the value
                    Cura.MachineManager.setSettingForAllExtruders(preferenceId, "value", value)
                    if (extraPreferenceId != "") // if there is another preference to set with the same value
                        Cura.MachineManager.setSettingForAllExtruders(extraPreferenceId, "value", value)
                    if (extraFunc != null && typeof(extraFunc) == "function") // extra function to execute afterwards
                        extraFunc()
                }
            }
        }
    }
}
