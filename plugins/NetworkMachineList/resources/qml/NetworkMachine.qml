// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import UM 1.1 as UM
import Cura 1.0 as Cura
import QtGraphicalEffects 1.0

Item {
    id: device

    width: base.width - 20
    height: machineStates.printing || machineStates.heating || machineStates.calibrating ? 170 : 130
    x : 200

    property bool extraInfoEnabled: false

    property string uid
    property string name
    property string ip
    property string material
    property string nozzle
    property string deviceModel
    property var  fwVersion
    property string printingFile
    property string elapsedTime
    property string estimatedTime
    property bool hasPin

    property bool canceling

    property var machineStates

    Connections
    {
        target: Cura.NetworkMachineListModel

        // property updates
        onNameChange: {
            if (uid != arguments[0]) return
            console.log("changing name to:" + arguments[1])
            inputDeviceName.text = lblDeviceName.text = arguments[1]
        }
        onPrintProgress: {
            if (uid != arguments[0]) return
            progressBar.value = arguments[1]
        }
        onTempProgress: {
            if (uid != arguments[0]) return
            if (!machineStates.heating) return
            if (machineStates.printing || machineStates.calibrating || machineStates.uploading) return
            progressBar.value = arguments[1]
        }
        onCalibrationProgress: {
            if (uid != arguments[0]) return
            progressBar.value = arguments[1]
        }

        onStateChange: {
            if (uid != arguments[0]) return
            machineStates = arguments[1]

            containerSayHi.visible = !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !machineStates.calibrating && !machineStates.bed_occupied
        }
    }

    states: State {
        name: "anchored"
        AnchorChanges { target: device; anchors.left: parent.right }
    }

    transitions: Transition {
        AnchorAnimation { duration: 500; easing.type: Easing.InOutBounce; easing.overshoot: 2 }
    }

    Component.onCompleted: {
        device.state = "anchored"
    }

    // Background
    RectangularGlow {
        id: effect
        anchors.fill: device
        anchors.bottomMargin: 15
        glowRadius: 5
        spread: 0
        color: "#121212"
        cornerRadius: rect.radius

        Rectangle {
            id: rect
            anchors.fill: parent
            color: "#2D2D2D"
            radius: 2
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (inputDeviceName.visible) {
                        inputDeviceName.visible = false
                        lblDeviceName.visible = true
                    }
                }
                onWheel: nMachineList.flick(0, wheel.angleDelta.y * 5)
            }
        }
    }

    // Printer icon
    RectangularGlow {
        id: printerIconShadow
        x: 20; y: 15
        width: 37; height: 37
        glowRadius: 5
        color: "#121212"
        cornerRadius: printerIconBackground.radius
        Rectangle {
            id: printerIconBackground
            width: 35; height: 35
            color: "#2D2D2D"
            radius: 100
        }
        Text {
            id: printerIcon
            anchors.centerIn: parent
            bottomPadding: 4; rightPadding: 2
            font { family: zaxeIconFont.name; pointSize: 18 }
            color: "white"
            text: "j"
        }
    }

    // Device name input
    TextField {
        id: inputDeviceName
        visible: false
        selectByMouse: true
        x: 90; y: 16
        width: 200; height: 25
        color: "white"; font.pointSize: 14; font.bold: true
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
                Cura.NetworkMachineManager.ChangeName(device.uid, lblDeviceName.text)
                inputDeviceName.visible = false;
                lblDeviceName.visible = true;
                event.accepted = true;
            }
        }
    }

    Label {
        id: lblDeviceName
        x: 95; y: 20
        color: "white"; font.pointSize: 14; font.bold: true
        text: device.name
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                inputDeviceName.text = name
                lblDeviceName.visible = false;
                inputDeviceName.visible = true;
            }
        }
    }

    Label {
        id: lblDeviceStatus
        color: "gray"; font.pointSize: 11
        anchors.top: lblDeviceName.bottom
        anchors.left: lblDeviceName.left
        topPadding: 3
        text: {
            if (machineStates.bed_occupied)
                return "Bed is occuppied..."
            else if (machineStates.paused)
                return "Paused"
            else if (machineStates.printing)
                return "Printing..."
            else if (machineStates.uploading)
                return "Uploading..."
            else if (machineStates.calibrating)
                return "Calibrating..."
            else if (machineStates.heating)
                return "Heating..."
            else
                return "Ready to print!"
        }
    }

    Rectangle {
        id: containerSayHi
        visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !machineStates.calibrating && !machineStates.bed_occupied

        RectangularGlow {
            id: sayHiBtnShadow
            x: 390; y: 15
            width: 37; height: 37
            glowRadius: 5
            color: "#121212"
            cornerRadius: 100
        }


        RoundButton {
            id: btnSayHi
            x: 385; y: 22
            font { family: zaxeIconFont.name; pointSize: 18; }
            text: "m"
            contentItem: Label {
                text: btnSayHi.text
                font: btnSayHi.font
                color: btnSayHi.down ? "gray" : "white"
            }
            background: Rectangle {
                color: "#202020"
                radius: btnSayHi.radius
            }
            onClicked: Cura.NetworkMachineManager.SayHi(device.uid)
        }
    }

    Rectangle {
        id: progressBarContainer
        visible: machineStates.printing || machineStates.heating
        width: device.width - 40
        y: 65
        anchors.horizontalCenter: parent.horizontalCenter
        //anchors.bottom: btnShowExtraInfo.top
        ProgressBar {
            id: progressBar
            value: 0
            padding: 2

            background: Rectangle {
                implicitWidth: progressBarContainer.width
                implicitHeight: 24
                color: "#121212" // "#121212"
                radius: 3
            }

            contentItem: Item {
                implicitWidth: device.width - 40
                implicitHeight: 16

                Rectangle {
                    width: progressBar.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: {
                        if (machineStates.heating)
                            return "#d9534f"
                        else if (machineStates.uploading)
                            return "orange"
                        else if (machineStates.calibrating)
                            return "blue"
                        else
                            return "#17a81a" // green
                    }
                    Text {
                        color: "white"
                        font { pointSize: 12 }
                        text: parseInt(progressBar.value * 100, 10) + "%"
                        anchors.horizontalCenter: parent.horizontalCenter
                        leftPadding: 15
                        topPadding: 2
                    }
                }
            }
        }
    }

    Button {
        id: btnStop
        x: 20; y: 111
        width: 30; height: 28
        visible: machineStates.printing && !machineStates.paused
        background: Rectangle {
            color: "#d9534f"
            radius: 2
        }
        contentItem: Text {
            color: "white"
            text: ""
            font { family: fontAwesomeSolid.name; pointSize: 12 }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: {
            // FIXME no confirmation
            Cura.NetworkMachineManager.Cancel(device.uid)
        }
    }

    Button {
        id: btnPrintNow
        x: 20; y: 70
        width: 95; height: 30
        visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied
        z: 1
        background: Rectangle {
            border.color: "black"
            border.width: 1
            color: "#191717"
            radius: 2
        }
        contentItem: Text {
            leftPadding: 5
            color: "white"
            text: "o"
            font { family: zaxeIconFont.name; pointSize: 12 }
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
        Label {
            color: "white"
            leftPadding: 25
            topPadding: 2
            font { pointSize: 12; bold: true}
            anchors.top: parent.contentItem.top
            anchors.left: parent.left
            horizontalAlignment: Text.AlignLeft
            text: " Print now"
        }
    }

    Button {
        id: btnPreheat
        x: 114; y: 70
        width: 40; height: 30
        visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied

        background: Rectangle {
            color: machineStates.preheat ? "#d9534f" : "#191717"
            radius: 2
            border.color: "black"
            border.width: 1
        }
        contentItem: Text {
            color: "white"
            text: "e"
            font { family: zaxeIconFont.name; pointSize: 12 }
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: Cura.NetworkMachineManager.TogglePreheat(device.uid)
    }

    Button {
        id: btnPause
        x: 49; y: 110
        width: 70; height: 30
        visible: machineStates.printing && !machineStates.paused
        z: 1
        background: Rectangle {
            color: "#191717"
            radius: 2
        }
        contentItem: Text {
            leftPadding: 3
            color: "white"
            text: ""
            font { family: fontAwesomeSolid.name; pointSize: 12 }
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
        Label {
            color: "white"
            leftPadding: 22
            topPadding: 2
            font { pointSize: 12; bold: true}
            anchors.top: parent.contentItem.top
            anchors.left: parent.left
            horizontalAlignment: Text.AlignLeft
            text: " Pause"
        }
        onClicked: Cura.NetworkMachineManager.Pause(device.uid)
    }

    Button {
        id: btnResume
        x: 20; y: 110
        width: 82; height: 30
        visible: machineStates.paused
        z: 1
        background: Rectangle {
            color: "#17a81a"
            radius: 2
        }
        contentItem: Text {
            leftPadding: 3
            color: "white"
            text: ""
            font { family: fontAwesomeSolid.name; pointSize: 12 }
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }
        Label {
            color: "white"
            leftPadding: 22
            topPadding: 2
            font { pointSize: 12; bold: true}
            anchors.top: parent.contentItem.top
            anchors.left: parent.left
            horizontalAlignment: Text.AlignLeft
            text: " Resume"
        }
        onClicked: Cura.NetworkMachineManager.Resume(device.uid)
    }

    Button {
        id: btnShowExtraInfo
        x: 385; y: machineStates.printing || machineStates.heating || machineStates.calibrating ? 102 : 62
        width: 37; height: 30
        font { pointSize: 30; bold: true }
        background: Rectangle {
            color: "#2D2D2D"
        }
        contentItem: Text {
            color: "#3e3e3e"
            text: "..."
            font: btnShowExtraInfo.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onClicked: {
            if (extraInfoEnabled) {
                containerExtraInfo.visible = false
                containerExtraInfo.stateVisible = false
                device.height -= containerExtraInfo.height - 25
                btnShowExtraInfo.contentItem.text = "..."
                extraInfoEnabled = false
            } else {
                containerExtraInfo.visible = true
                containerExtraInfo.stateVisible = true
                device.height += containerExtraInfo.height - 25
                btnShowExtraInfo.contentItem.text = " x"
                extraInfoEnabled = true
            }
        }
        onHoveredChanged: {
            btnShowExtraInfo.contentItem.color = hovered ? "gray" : "#3e3e3e"
        }
    }

    Grid {
        id: containerExtraInfo
        property bool stateVisible: false
        visible: false
        columns: 2
        anchors {
            top: btnShowExtraInfo.bottom
            left: parent.left
            right: parent.right
        }

        topPadding: 18
        bottomPadding: 15
        leftPadding: 20

        states: [
            State { when: stateVisible;
                PropertyChanges {   target: containerExtraInfo; opacity: 1.0    }
            },
            State { when: !stateVisible;
                PropertyChanges {   target: containerExtraInfo; opacity: 0.0    }
            }
        ]
        transitions: Transition {
            NumberAnimation { property: "opacity"; duration: 500}
        }

        Text { text: "File name"; color: "white"; font.bold: true; width: 125; visible: machineStates.printing }
        Text { text: device.printingFile; color: "white"; visible: machineStates.printing }
        Text { text: "Elapsed time"; color: "white"; font.bold: true; width: 125; visible: machineStates.printing }
        Text { id: txtElapsedTime; text: device.elapsedTime; color: "white"; visible: machineStates.printing }
        Text { text: "Est. time"; color: "white"; font.bold: true; width: 125; visible: machineStates.printing }
        Text { text: device.estimatedTime; color: "white"; visible: machineStates.printing }
        Text { text: "Material"; color: "white"; font.bold: true; width: 125 }
        Text { text: base.materialNames[device.material]; color: "white" }
        Text { text: "Nozzle"; color: "white"; font.bold: true; width: 125 }
        Text { text: device.nozzle + " mm"; color: "white" }
        Text { text: "Network IP"; color: "white"; font.bold: true; width: 125 }
        Text { text: device.ip; color: "white" }

        // elapsed time calculation
        Timer {
            interval: 1000
            running: machineStates.printing
            repeat: true
            onTriggered: {
                device.elapsedTime = parseFloat(device.elapsedTime) + 1
                txtElapsedTime.text = base.toHHMMSS(device.elapsedTime)
            }
        }
    }

}
