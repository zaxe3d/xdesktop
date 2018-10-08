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
    height: mainLayout.height + 35
    x : 200 // to animate from right

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
        AnchorChanges { target: device; anchors.left: parent.left }
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
        glowRadius: 4
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

        // Main layout
        ColumnLayout {
            id: mainLayout
            spacing: 10

            // First row
            Rectangle {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: parent.width - 15
                Layout.preferredHeight: 55
                color: "#2D2D2D"

                RowLayout {
                    id: row0
                    // First column

                    // Printer icon
                    Rectangle {
                        Layout.preferredWidth: 60; Layout.minimumHeight: 50
                        Layout.leftMargin: 20
                        Layout.topMargin: 15
                        color: "#2D2D2D"
                        //color: "green"
                        RectangularGlow {
                            width: 37; height: 37
                            id: printerIconShadow
                            glowRadius: 5
                            color: "#121212"
                            cornerRadius: printerIconBackground.radius
                            Rectangle {
                                id: printerIconBackground
                                width: 35; height: 35
                                color: "#2D2D2D"
                                radius: 100
                                Text {
                                    id: printerIcon
                                    anchors.centerIn: parent
                                    bottomPadding: 4; rightPadding: 2
                                    font { family: zaxeIconFont.name; pointSize: 18 }
                                    color: "white"
                                    text: "j"
                                }
                            }
                        }
                    }

                    // Second column
                    Rectangle {
                        Layout.preferredWidth: 295; Layout.minimumHeight: 37
                        Layout.topMargin: 5
                        color: "#2D2D2D"
                        // device name input
                        TextField {
                            id: inputDeviceName
                            visible: false
                            selectByMouse: true
                            color: "white"; font.pointSize: 14; font.bold: true
                            text: lblDeviceName.text
                            padding: 1
                            width: 200; height: 23
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
                        // device name label
                        Label {
                            id: lblDeviceName
                            color: "white"; font.pointSize: 14; font.bold: true
                            text: device.name
                            topPadding: 3; leftPadding: 5
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
                        // device status label
                        Label {
                            id: lblDeviceStatus
                            color: "gray"; font.pointSize: 11
                            anchors.top: lblDeviceName.bottom
                            anchors.left: lblDeviceName.left
                            topPadding: 2; leftPadding: 5
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
                    }
                    // Third column
                    // say hi
                    Rectangle {
                        id: containerSayHi
                        Layout.preferredWidth: 37; Layout.minimumHeight: 50
                        color: "#2D2D2D"
                        visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !machineStates.calibrating && !machineStates.bed_occupied
                        Layout.topMargin: 10

                        RectangularGlow {
                            id: sayHiBtnShadow
                            width: 37; height: 37
                            glowRadius: 5
                            color: "#121212"
                            cornerRadius: 100
                        }

                        RoundButton {
                            id: btnSayHi
                            contentItem: Label {
                                anchors.centerIn: parent
                                text: "m"
                                font { family: zaxeIconFont.name; pointSize: 18; }
                                color: btnSayHi.down ? "gray" : "white"
                            }
                            background: Rectangle {
                                color: "#202020"
                                radius: btnSayHi.radius
                            }
                            onClicked: Cura.NetworkMachineManager.SayHi(device.uid)
                        }
                    }
                }
            }

            // Second row - message rows
            Rectangle {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: parent.width - 15
                Layout.preferredHeight: messageBarLayout.height
                color: "red"

                RowLayout {
                    id: row1
                    // First column

                    ColumnLayout {
                        id: messageBarLayout
                        spacing: 5

                        // Message bar row 1
                        Rectangle {
                            visible: machineStates.bed_occupied
                            Layout.preferredWidth: device.width - 40; Layout.minimumHeight: childrenRect.height
                            Layout.alignment: Qt.AlignLeft
                            Layout.leftMargin: 20
                            border.width: 1; border.color: "black"
                            radius: 2
                            color: "#2D2D2D"
                            Text {
                                width: parent.width
                                font { pointSize: 12 }
                                padding: 10
                                color: "green"
                                horizontalAlignment: Text.AlignLeft
                                wrapMode: Text.WordWrap
                                text: "Please take your print!"
                            }
                        }

                        // danger message
                        Rectangle {
                            visible: false
                            Layout.preferredWidth: device.width - 40; Layout.minimumHeight: childrenRect.height
                            Layout.alignment: Qt.AlignLeft
                            Layout.leftMargin: 20
                            border.width: 1; border.color: "#a94442"
                            radius: 2
                            color: "#2D2D2D"
                            Text {
                                width: parent.width
                                font { pointSize: 12 }
                                padding: 10
                                color: "#a94442"
                                horizontalAlignment: Text.AlignLeft
                                wrapMode: Text.WordWrap
                                text: "The material in the device does not match with the material you choose. Please slice again with the correct material"
                            }
                        }
                    }
                }
            }

            // Third row
            Rectangle {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: parent.width - 15
                Layout.preferredHeight: 25
                visible: machineStates.printing || machineStates.heating
                color: "red"

                RowLayout {
                    id: row2
                    // First column

                    // Progress bar
                    Rectangle {
                        id: progressBarContainer
                        Layout.preferredWidth: device.width - 40; Layout.minimumHeight: 25
                        Layout.alignment: Qt.AlignLeft
                        Layout.leftMargin: 20
                        color: "#2D2D2D"

                        ProgressBar {
                            id: progressBar
                            value: 0
                            padding: 2

                            background: Rectangle {
                                implicitWidth: progressBarContainer.width
                                implicitHeight: 24
                                color: "#121212"
                                radius: 3
                            }

                            contentItem: Item {
                                implicitWidth: device.width - 44
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
                }
            }
            // Fourth row
            Rectangle {
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: parent.width - 15
                Layout.preferredHeight: 30
                color: "#2D2D2D"
                //color: "red"

                RowLayout {
                    id: row3
                    // First column

                    // Buttons (play - pause - print - etc...)
                    Rectangle {
                        Layout.preferredWidth: 358; Layout.minimumHeight: 28
                        Layout.leftMargin: 20
                        color: "#2D2D2D"

                        Button {
                            id: btnStop
                            width: 30; height: 30
                            visible: machineStates.heating || (machineStates.printing && !machineStates.paused)
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
                            width: 40; height: 30
                            x: 95
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
                            x: 29
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
                    }
                    // Second column - show extra info button
                    Rectangle {
                        Layout.preferredWidth: 50; Layout.minimumHeight: 30
                        color: "#2D2D2D"
                        Button {
                            id: btnShowExtraInfo
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
                                if (containerExtraInfo.visible) {
                                    containerExtraInfo.visible = false
                                    btnShowExtraInfo.contentItem.text = "..."
                                } else {
                                    containerExtraInfo.visible = true
                                    btnShowExtraInfo.contentItem.text = " x"
                                }
                            }
                            onHoveredChanged: {
                                btnShowExtraInfo.contentItem.color = hovered ? "gray" : "#3e3e3e"
                            }
                        }
                    }
                }
            }
            // Fifth row
            Rectangle {
                id: containerExtraInfo
                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: parent.width - 15
                Layout.preferredHeight: extraInfoGrid.height
                color: "#2D2D2D"
                visible: false

                RowLayout {
                    id: row4
                    // First column

                    // Extra info grid
                    Rectangle {
                        Layout.preferredWidth: 358; Layout.minimumHeight: extraInfoGrid.height
                        Layout.topMargin: 5; Layout.leftMargin: 20
                        color: "#2D2D2D"

                        Grid {
                            id: extraInfoGrid
                            property bool stateVisible: false
                            columns: 2

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
                }
            }
        }
    }
}

