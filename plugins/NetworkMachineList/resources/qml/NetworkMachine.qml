// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import UM 1.1 as UM
import Cura 1.0 as Cura
import QtGraphicalEffects 1.0

Item {
    id: device

    width: base.width - 20
    height: 165

    property string uid
    property string name
    property string ip


    RectangularGlow {
        id: effect
        anchors.fill: rect
        glowRadius: 5
        spread: 0
        color: "#121212"
        cornerRadius: rect.radius
    }

    Rectangle {
        id: rect
        anchors.fill: parent
        anchors.bottomMargin: 15
        color: "#2D2D2D"
        radius: 2
    }

    RectangularGlow {
        id: printerIconShadow
        x: 20; y: 15
        width: 37; height: 37
        glowRadius: 5
        color: "#121212"
        cornerRadius: printerIconBackground.radius
    }

    Rectangle {
        id: printerIconBackground
        x: 20; y: 15
        width: 35; height: 35
        color: "#2D2D2D"
        radius: 100
    }

    Text {
        id: printerIcon
        x: 29; y: 22
        font { family: zaxeIconFont.name; pointSize: 18 }
        color: "white"
        text: "j"
    }

    TextField {
        visible: false
        selectByMouse: true
        id: inputDeviceName
        x: 90; y: 15
        width: 200; height: 25
        color: "white"; font.pointSize: 12; font.bold: true
        text: lblDeviceName.text
        padding: 1

        background: Rectangle {
            color: "#2D2D2D"
            border.color: "#3e3e3e"
            border.width: 1
            radius: 2
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Escape) {
                inputDeviceName.text = "";
                event.accepted = true;
            } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                console.log("enter pressed");
                lblDeviceName.text = inputDeviceName.text;
                inputDeviceName.visible = false;
                lblDeviceName.visible = true;
                event.accepted = true;
            }
        }
    }

    Label {
        visible: true
        id: lblDeviceName
        x: 95; y: 20
        color: "white"; font.pointSize: 12; font.bold: true
        text: device.name
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                lblDeviceName.visible = false;
                inputDeviceName.visible = true;
            }
        }
    }

    RectangularGlow {
        id: sayHiBtnShadow
        x: 390; y: 15
        width: 37; height: 37
        glowRadius: 5
        color: "#121212"
        cornerRadius: 100
    }


    RoundButton {
        x: 385; y: 22
        id: btnSayHi
        font { family: zaxeIconFont.name; pointSize: 18; }
        text: "m"
        onClicked: Cura.NetworkMachineManager.SayHi(device.uid)
        contentItem: Label {
            text: btnSayHi.text
            font: btnSayHi.font
            color: btnSayHi.down ? "gray" : "white"
        }
        background: Rectangle {
            color: "#202020"
            radius: btnSayHi.radius
        }
    }
}
