// Copyright (c) 2017 Ultimaker B.V..width
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import UM 1.1 as UM
import Cura 1.0 as Cura
import QtGraphicalEffects 1.0

Item {
    id: device

    width: networkMachineList.width - 20
    height: mainLayout.height + 10
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
    property string elapsedTimeTxt
    property string estimatedTime
    property string snapshot
    property bool hasSnapshot
    property bool hasPin
    property bool hasFWUpdate
    property var progress: 0

    property bool canceling

    // states
    property var machineStates

    // warnings
    property bool materialWarning
    property bool modelCompatibilityWarning

    property string nextState

    Connections
    {
        target: Cura.NetworkMachineListModel

        // property updates
        onNameChange: {
            if (uid != arguments[0]) return
            inputDeviceName.text = lblDeviceName.text = arguments[1]
        }
        onFileChange: {
            if (uid != arguments[0]) return
            printingFile = arguments[1]
            elapsedTime = arguments[2] // reset the timer as well
            estimatedTime = arguments[3]
            imgSnapshot.sourceChanged()
        }
        onNozzleChange: {
            if (uid != arguments[0]) return
            nozzle = arguments[1]
        }
        onMaterialChange: {
            if (uid != arguments[0]) return
            material = arguments[1]
        }
        // progress updates
        onPrintProgress: {
            if (uid != arguments[0]) return
            progress = arguments[1]
        }
        onTempProgress: {
            if (uid != arguments[0]) return
            if (!machineStates.heating) return
            if (machineStates.printing || machineStates.calibrating || machineStates.uploading) return
            progress = arguments[1]
        }
        onCalibrationProgress: {
            if (uid != arguments[0]) return
            progress = arguments[1]
        }
        onUploadProgress: {
            if (uid != arguments[0]) return
            progress = arguments[1]
        }
        onStateChange: {
            if (uid != arguments[0]) return
            machineStates = arguments[1]
            progress = 0 // new state new bar
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

    function showConfirmation(state) {
        device.nextState = state
        confirmationPane.visible = true
    }
    function showPinCodeEntry(state) {
        inputPinCode.text = ""
        device.nextState = state
        pinCodeEntryPane.visible = true
    }

    function applyState() {
        var pin = device.hasPin ? inputPinCode.text : ""

        switch(device.nextState) {
            case "cancel":
                Cura.NetworkMachineManager.Cancel(device.uid, pin)
                break;
            case "pause":
                Cura.NetworkMachineManager.Pause(device.uid, pin)
                break;
            case "update":
                Cura.NetworkMachineManager.FWUpdate(device.uid)
                break;
        }
        device.nextState = ""
        confirmationPane.visible = false
    }
    function enterPinCode(pin) {
        pinCodeEntryPane.visible = false
        applyState()
    }

    // Top Border
    Rectangle {
        width: parent.width
        height: UM.Theme.getSize("default_lining").width
        anchors.top: parent.top
        anchors.left: parent.left
        color: UM.Theme.getColor("sidebar_item_dark")
        z: 1
    }

    // Background
    Rectangle {
        anchors.fill: device
        color: UM.Theme.getColor("sidebar_item_light")
        MouseArea {
            propagateComposedEvents: true
            anchors.fill: parent
            onClicked: {
                mouse.accepted = false
                if (inputDeviceName.visible) {
                    inputDeviceName.visible = false
                    lblDeviceName.visible = true
                }
            }
        }

        // Pin code entry
        Rectangle {
            id: pinCodeEntryPane
            color: UM.Theme.getColor("sidebar_item_light")
            width: device.width - 90 - btnShowExtraInfo.width - 20; height: 45
            x: parent.width - width - 50
            z: 5
            visible: false
            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                TextField {
                    id: inputPinCode
                    echoMode: TextInput.Password
                    placeholderText: catalog.i18nc("@label", "Enter pin code...")
                    selectByMouse: true
                    font: UM.Theme.getFont("medium")
                    color: UM.Theme.getColor("text_sidebar")
                    padding: 0
                    Layout.preferredWidth: 235; Layout.preferredHeight: 30
                    anchors {
                        top: parent.top
                        left: parent.left
                        topMargin: 0
                    }

                    background: Rectangle {
                        color: UM.Theme.getColor("sidebar_item_light")
                        border.width: 0
                        radius: 2
                        // Bottom border only
                        Rectangle { width: parent.width; height: UM.Theme.getSize("default_lining").height; anchors.bottom: parent.bottom; anchors.bottomMargin: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }
                    }
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Escape) {
                            inputPinCode.text = "";
                            event.accepted = true;
                        } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                            enterPinCode(inputPinCode.text)
                            inputDeviceName.visible = false;
                            lblDeviceName.visible = true;
                            event.accepted = true;
                        }
                    }
                }
                Button {
                    Layout.preferredHeight: 27
                    background: Rectangle {
                        color: UM.Theme.getColor("button_blue")
                        border.color: UM.Theme.getColor("button_blue")
                        border.width: UM.Theme.getSize("default_lining").width
                        radius: 10
                    }
                    contentItem: Text {
                        color: UM.Theme.getColor("text_white")
                        width: parent.width
                        text: catalog.i18nc("@label", "OK")
                        font: UM.Theme.getFont("medium_bold")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        enterPinCode(inputPinCode.text)
                    }
                }
            }
        }
        // Confirmation pane
        Rectangle {
            id: confirmationPane
            color: UM.Theme.getColor("sidebar_item_light")
            width: device.width - 90 - btnShowExtraInfo.width - 20; height: 45
            x: parent.width - width - 50
            z: 5
            visible: false
            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                Label {
                    font: UM.Theme.getFont("large_semi_bold")
                    color: UM.Theme.getColor("text_sidebar")
                    text: catalog.i18nc("@label", "Are you sure?")
                }
                Button {
                    Layout.preferredHeight: 27
                    background: Rectangle {
                        color: UM.Theme.getColor("button_danger")
                        border.color: UM.Theme.getColor("button_danger")
                        border.width: UM.Theme.getSize("default_lining").width
                        radius: 10
                    }
                    contentItem: Text {
                        color: UM.Theme.getColor("text_white")
                        width: parent.width
                        text: catalog.i18nc("@label", "YES")
                        font: UM.Theme.getFont("medium_bold")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        applyState()
                    }
                }
                Button {
                    Layout.preferredHeight: 27
                    background: Rectangle {
                        color: UM.Theme.getColor("button_white")
                        border.color: UM.Theme.getColor("button_blue")
                        border.width: UM.Theme.getSize("default_lining").width
                        radius: 10
                    }
                    contentItem: Text {
                        color: UM.Theme.getColor("button_blue")
                        width: parent.width
                        text: catalog.i18nc("@label", "NO")
                        font: UM.Theme.getFont("medium_bold")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        confirmationPane.visible = false
                    }
                }
            }
        }
        // Main layout
        ColumnLayout {
            id: mainLayout
            spacing: 10

            // First row - main
            Rectangle {
                Layout.preferredWidth: device.width - UM.Theme.getSize("sidebar_item_margin").width
                color: UM.Theme.getColor("sidebar_item_light")
                Layout.preferredHeight: 90

                // First row columns
                RowLayout {
                    id: leftPane
                    Layout.preferredHeight: 90

                    // First column (left pane)
                    // Printer model name / snapshot
                    Rectangle {
                        color: UM.Theme.getColor("sidebar_item_light")
                        Layout.preferredWidth: 90; Layout.preferredHeight: 90
                        Layout.topMargin: 5
                        z: 6

                        Rectangle {
                            width: 68; height: 68
                            Layout.leftMargin: 20
                            z: 6
                            color: UM.Theme.getColor("sidebar_item_dark")
                            anchors.centerIn: parent
                            radius: 10

                            Image {
                                id: imgSnapshot
                                anchors.centerIn: parent
                                visible: !machineStates.calibrating && (machineStates.bed_occupied || machineStates.printing || machineStates.heating) && device.hasSnapshot
                                source: visible ? device.snapshot : ""
                                width: 60
                                height: width
                            }

                            Text {
                                id: printerIcon
                                anchors.centerIn: parent
                                visible: !imgSnapshot.visible
                                font: UM.Theme.getFont("xx_large")
                                color: UM.Theme.getColor("text_sidebar_light")
                                text: device.deviceModel.replace("plus", "+").toUpperCase()
                            }
                        }
                    }

                    // Second column (right pane)
                    Rectangle {
                        id: rightPane
                        color: UM.Theme.getColor("sidebar_item_light")
                        Layout.preferredWidth: device.width - 90
                        Layout.preferredHeight: 90

                        // Right pane rows (Printer name, status and progress bar
                        ColumnLayout {
                            spacing: 5

                            // First row (right pane)
                            Rectangle {
                                Layout.preferredWidth: device.width - 90 - UM.Theme.getSize("sidebar_item_margin").width
                                Layout.preferredHeight: 37
                                color: UM.Theme.getColor("sidebar_item_light")
                                // device name input
                                TextField {
                                    id: inputDeviceName
                                    visible: false
                                    selectByMouse: true
                                    font: UM.Theme.getFont("large")
                                    color: UM.Theme.getColor("text_sidebar")
                                    text: lblDeviceName.text
                                    padding: 0
                                    width: 200; height: 30
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        topMargin: 12
                                        leftMargin: -4
                                    }

                                    background: Rectangle {
                                        color: UM.Theme.getColor("sidebar_item_light")
                                        border.width: 0
                                        radius: 2
                                        // Bottom border only
                                        Rectangle { width: parent.width; height: UM.Theme.getSize("default_lining").height; anchors.bottom: parent.bottom; anchors.bottomMargin: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }
                                    }
                                    Keys.onPressed: {
                                        if (event.key == Qt.Key_Escape) {
                                            inputDeviceName.text = "";
                                            event.accepted = true;
                                        } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                                            lblDeviceName.text = name = inputDeviceName.text;
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
                                    font: UM.Theme.getFont("large")
                                    color: UM.Theme.getColor("text_sidebar")
                                    text: device.name
                                    anchors.bottom : parent.bottom
                                    width: 205
                                    clip: true
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
                                // Button pane
                                RowLayout {
                                    id: buttonPane
                                    Layout.preferredWidth: 120; Layout.preferredHeight: 40
                                    anchors.right: parent.right; anchors.top: parent.top

                                    // Preheat button
                                    Button {
                                        id: btnPreheat
                                        visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied
                                        implicitWidth: 30; implicitHeight: 40
                                        anchors.top: parent.top
                                        anchors.topMargin: 7

                                        background: Rectangle {
                                            color: UM.Theme.getColor("sidebar_item_light")
                                        }
                                        contentItem: Text {
                                            font: UM.Theme.getFont("zaxe_icon_set")
                                            color: machineStates.preheat ? UM.Theme.getColor("text_heating") : UM.Theme.getColor("text_sidebar")
                                            text: "I"
                                            anchors.top: parent.top
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: Cura.NetworkMachineManager.TogglePreheat(device.uid)
                                        // this hover state makes it silly
                                        //onHoveredChanged: {
                                        //    btnPreheat.contentItem.color = hovered
                                        //        ? UM.Theme.getColor("text_heating")
                                        //        : machineStates.preheat ? UM.Theme.getColor("text_heating") : UM.Theme.getColor("text_sidebar")
                                        //}
                                    }

                                    // Pause button
                                    Button {
                                        id: btnPause
                                        visible: machineStates.printing && !machineStates.paused
                                        implicitWidth: 30; implicitHeight: 40
                                        anchors.top: parent.top
                                        padding: 0
                                        anchors.topMargin: 3

                                        background: Rectangle {
                                            color: UM.Theme.getColor("sidebar_item_light")
                                        }
                                        contentItem: Text {
                                            font: UM.Theme.getFont("zaxe_icon_set")
                                            color: UM.Theme.getColor("text_sidebar")
                                            text: "K"
                                            anchors.top: parent.top
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: {
                                            if (device.hasPin) {
                                                showPinCodeEntry("pause")
                                            } else {
                                                showConfirmation("pause")
                                            }
                                        }
                                        onHoveredChanged: {
                                            btnPause.contentItem.color = hovered
                                                ? UM.Theme.getColor("text_sidebar_hover")
                                                : UM.Theme.getColor("text_sidebar")
                                        }
                                    }

                                    // Resume button
                                    Button {
                                        id: btnResume
                                        visible: machineStates.paused
                                        implicitWidth: 65; implicitHeight: 40
                                        anchors.top: parent.top
                                        anchors.topMargin: 1
                                        padding: 0

                                        background: Rectangle {
                                            color: UM.Theme.getColor("sidebar_item_light")
                                        }
                                        contentItem: Text {
                                            font: UM.Theme.getFont("zaxe_icon_set")
                                            color: UM.Theme.getColor("text_sidebar")
                                            text: catalog.i18nc("@button", "e")
                                            anchors.top: parent.top
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: Cura.NetworkMachineManager.Resume(device.uid)
                                        onHoveredChanged: {
                                            btnResume.contentItem.color = hovered
                                                ? UM.Theme.getColor("text_sidebar_hover")
                                                : UM.Theme.getColor("text_sidebar")
                                        }
                                    }

                                    // Left Border
                                    Rectangle {
                                        visible: !machineStates.bed_occupied && !machineStates.uploading && !machineStates.calibrating && !machineStates.paused
                                        width: UM.Theme.getSize("default_lining").width
                                        height: 37
                                        anchors.top: parent.top
                                        anchors.topMargin: -3
                                        anchors.rightMargin: 5
                                        color: UM.Theme.getColor("sidebar_item_dark")
                                        z: 1
                                    }

                                    // Cancel button
                                    Button {
                                        id: btnCancel
                                        visible: (!machineStates.calibrating && machineStates.heating) || (machineStates.printing && !machineStates.paused)
                                        implicitWidth: 30; implicitHeight: 40
                                        anchors.top: parent.top
                                        padding: 0
                                        anchors.topMargin: 3

                                        background: Rectangle {
                                            color: UM.Theme.getColor("sidebar_item_light")
                                        }
                                        contentItem: Text {
                                            font: UM.Theme.getFont("zaxe_icon_set")
                                            color: UM.Theme.getColor("text_danger")
                                            text: "L"
                                            anchors.top: parent.top
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: {
                                            if (device.hasPin) {
                                                showPinCodeEntry("cancel")
                                            } else {
                                                showConfirmation("cancel")
                                            }
                                        }
                                        onHoveredChanged: {
                                            btnCancel.contentItem.color = hovered
                                                ? UM.Theme.getColor("text_sidebar_hover")
                                                : UM.Theme.getColor("text_danger")
                                        }
                                    }

                                    // SayHi button
                                    Button {
                                        id: btnSayHi
                                        visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !machineStates.calibrating && !machineStates.bed_occupied
                                        implicitWidth: 30; implicitHeight: 37
                                        anchors.top: parent.top
                                        padding: 0
                                        anchors.topMargin: 3

                                        background: Rectangle {
                                            color: UM.Theme.getColor("sidebar_item_light")
                                        }
                                        contentItem: Text {
                                            font: UM.Theme.getFont("zaxe_icon_set")
                                            color: UM.Theme.getColor("text_sidebar")
                                            text: "J"
                                            anchors.top: parent.top
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: Cura.NetworkMachineManager.SayHi(device.uid)
                                        onHoveredChanged: {
                                            btnSayHi.contentItem.color = hovered
                                                ? UM.Theme.getColor("text_sidebar_hover")
                                                : UM.Theme.getColor("text_sidebar")
                                        }
                                    }
                                    // Right Border
                                    Rectangle {
                                        width: UM.Theme.getSize("default_lining").width
                                        height: 37
                                        anchors.top: parent.top
                                        anchors.topMargin: -3
                                        anchors.rightMargin: 5
                                        color: UM.Theme.getColor("sidebar_item_dark")
                                        z: 1
                                    }
                                    //Label {
                                    //    font: UM.Theme.getFont("zaxe_icon_set")
                                    //    color: "red"
                                    //    text: "L"
                                    //}
                                    Button {
                                        id: btnShowExtraInfo
                                        implicitWidth: 30; implicitHeight: 40

                                        padding: 0
                                        anchors.top: parent.top
                                        anchors.topMargin: 3

                                        background: Rectangle {
                                            color: UM.Theme.getColor("sidebar_item_light")
                                        }
                                        contentItem: Text {
                                            color: UM.Theme.getColor("text_sidebar")
                                            font: UM.Theme.getFont("zaxe_icon_set_medium")
                                            text: "M"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        onClicked: {
                                            if (containerExtraInfo.visible) {
                                                containerExtraInfo.visible = false
                                                btnShowExtraInfo.contentItem.text = "M"
                                            } else {
                                                containerExtraInfo.visible = true
                                                btnShowExtraInfo.contentItem.text = "a"
                                            }
                                        }
                                        onHoveredChanged: {
                                            btnShowExtraInfo.contentItem.color = hovered
                                                ? UM.Theme.getColor("text_sidebar_hover")
                                                : UM.Theme.getColor("text_sidebar")
                                        }
                                    }
                                }
                            }

                            // Second row (right pane)
                            Rectangle {
                                Layout.preferredWidth: device.width - 90 - UM.Theme.getSize("sidebar_item_margin").width
                                Layout.preferredHeight: 23

                                color: UM.Theme.getColor("sidebar_item_light")
                                // Print Now button
                                Button {
                                    id: btnPrintNow
                                    visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied
                                    width: 130; height: 28
                                    anchors.top: parent.top
                                    anchors.topMargin: 11
                                    padding: 0
                                    SequentialAnimation {
                                        id: shakeAnim
                                        running: false
                                        NumberAnimation { target: btnPrintNow; property: "x"; to: -5; duration: 50 }
                                        NumberAnimation { target: btnPrintNow; property: "x"; to: 10; duration: 50 }
                                        NumberAnimation { target: btnPrintNow; property: "x"; to: -5; duration: 50 }
                                        NumberAnimation { target: btnPrintNow; property: "x"; to: 10; duration: 50 }
                                        NumberAnimation { target: btnPrintNow; property: "x"; to: 0; duration: 50 }
                                    }

                                    background: Rectangle {
                                        color: UM.Theme.getColor("sidebar_item_light")
                                        border.color: UM.Theme.getColor("text_blue")
                                        border.width: UM.Theme.getSize("default_lining").width
                                        radius: 10
                                    }
                                    contentItem: Text {
                                        font: UM.Theme.getFont("large")
                                        color: UM.Theme.getColor("text_blue")
                                        text: catalog.i18nc("@label", "Print now!")
                                        anchors.top: parent.top
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    onClicked: {
                                        // check if the slice is ready or if there is a model
                                        if (PrintInformation.preSliced) {
                                            var info = PrintInformation.preSlicedInfo
                                            if (!CuraApplication.platformActivity) {
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                shakeAnim.start()
                                            } else if (info.model != device.deviceModel.toUpperCase()) {
                                                device.modelCompatibilityWarning = true
                                                shakeAnim.start()
                                            } else if (info.material != device.material) {
                                                device.materialWarning = true
                                                shakeAnim.start()
                                            } else {
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                Cura.NetworkMachineManager.upload(device.uid) == false
                                            }
                                        } else {
                                            // 3 is Done
                                            if (UM.Backend.state != "undefined" && UM.Backend.state != 3 || !CuraApplication.platformActivity) {
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                shakeAnim.start()
                                            } else if (Cura.MachineManager.activeMachineName.replace("+", "PLUS") != device.deviceModel.toUpperCase()) {
                                                device.modelCompatibilityWarning = true
                                                shakeAnim.start()
                                            } else if (PrintInformation.materialNames[0] != device.material) {
                                                device.materialWarning = true
                                                shakeAnim.start()
                                            } else {
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                Cura.NetworkMachineManager.upload(device.uid) == false
                                            }
                                        }
                                    }
                                    onHoveredChanged: {
                                        btnPrintNow.contentItem.color = hovered
                                            ? UM.Theme.getColor("text_sidebar_hover")
                                            : UM.Theme.getColor("text_blue")
                                    }
                                }

                                // device status label
                                Label {
                                    id: lblDeviceStatus
                                    font: UM.Theme.getFont("large_semi_bold")
                                    color: UM.Theme.getColor("text_sidebar_medium")
                                    anchors { bottom: parent.bottom; left: parent.left }
                                    text: {
                                        if (machineStates.bed_occupied)
                                            return catalog.i18nc("@label", "Bed is occuppied...")
                                        else if (machineStates.paused)
                                            return catalog.i18nc("@label", "Paused")
                                        else if (machineStates.printing)
                                            return catalog.i18nc("@label", "Printing...")
                                        else if (machineStates.uploading)
                                            return catalog.i18nc("@label", "Uploading...")
                                        else if (machineStates.calibrating)
                                            return catalog.i18nc("@label", "Calibrating...")
                                        else if (machineStates.heating)
                                            return catalog.i18nc("@label", "Heating...")
                                        else
                                            return ""
                                    }
                                }

                                Label {
                                    visible: machineStates.calibrating || machineStates.printing || machineStates.heating || machineStates.uploading
                                    font: UM.Theme.getFont("large")
                                    color: UM.Theme.getColor("text_sidebar_medium")
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    text: "%" + parseInt(device.progress * 100, 10)
                                }
                            }

                            // Third row (right pane) - progress bar and messages

                            // Bed occuppied message
                            Rectangle {
                                visible: machineStates.bed_occupied
                                Layout.preferredWidth: device.width - 90 - UM.Theme.getSize("sidebar_item_margin").width
                                Layout.minimumHeight: childrenRect.height
                                Layout.alignment: Qt.AlignLeft
                                color: UM.Theme.getColor("sidebar_item_light")

                                Text {
                                    width: parent.width
                                    font: UM.Theme.getFont("medium")
                                    color: UM.Theme.getColor("text_success")
                                    horizontalAlignment: Text.AlignLeft
                                    wrapMode: Text.WordWrap
                                    text: catalog.i18nc("@label", "Please take your print!")
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: device.width - 90 - UM.Theme.getSize("sidebar_item_margin").width
                                Layout.preferredHeight: UM.Theme.getSize("progressbar").height
                                visible: machineStates.calibrating || machineStates.printing || machineStates.heating || machineStates.uploading

                                Rectangle {
                                    id: progressBar
                                    width: parent.width
                                    height: UM.Theme.getSize("progressbar").height
                                    radius: UM.Theme.getSize("progressbar_radius").width
                                    color: UM.Theme.getColor("progressbar_background")

                                    Rectangle {
                                        width: Math.max(parent.width * device.progress)
                                        height: parent.height
                                        radius: UM.Theme.getSize("progressbar_radius").width
                                        color: {
                                            if (machineStates.calibrating)
                                                return "orange"
                                            else if (machineStates.heating)
                                                return "red"
                                            else if (machineStates.uploading)
                                                return "#17a81a"
                                            else
                                                return "#009bdf"
                                        }
                                    }
                                }
                            }
                        }
                    } // End of Second column (right pane)
                } // End of First row columns
            } // End of First row - main

            // Second row - main (fullrow messages)
            // FW update available message
            Rectangle {
                visible: device.hasFWUpdate
                Layout.preferredWidth: Math.round(device.width - 65 - (UM.Theme.getSize("sidebar_item_margin").width * 2))
                Layout.minimumHeight: fwUpdateMessage.height
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: -Math.round(UM.Theme.getSize("sidebar_item_margin").height)
                Layout.bottomMargin: Math.round(UM.Theme.getSize("sidebar_item_margin").height * 2)
                Layout.rightMargin: UM.Theme.getSize("sidebar_item_margin").width
                color: UM.Theme.getColor("sidebar_item_light")

                Text {
                    id: fwUpdateMessageIcon
                    font: UM.Theme.getFont("zaxe_icon_set")
                    color: UM.Theme.getColor("text_danger")
                    horizontalAlignment: Text.AlignLeft
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: "d"
                }
                Text {
                    id: fwUpdateMessage
                    width: parent.width - (btnfwUpdate.visible ? btnfwUpdate.width : 0)

                    font: UM.Theme.getFont("medium")
                    color: UM.Theme.getColor("text_blue")
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                    anchors {
                        verticalCenter: fwUpdateMessageIcon.verticalCenter
                        left: fwUpdateMessageIcon.right
                        leftMargin: 1
                    }
                    text: catalog.i18nc("@info", "Firmware update available for your device")
                }
                Button {
                    id: btnfwUpdate
                    // only Z series has remote update
                    visible: deviceModel.search("z") == 0 && !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied
                    Layout.preferredHeight: 27
                    anchors {
                        verticalCenter: fwUpdateMessage.verticalCenter
                        left: fwUpdateMessage.right
                        leftMargin: 1
                    }
                    background: Rectangle {
                        color: UM.Theme.getColor("button_blue")
                        border.color: UM.Theme.getColor("button_blue")
                        border.width: UM.Theme.getSize("default_lining").width
                        radius: 10
                    }
                    contentItem: Text {
                        color: UM.Theme.getColor("text_white")
                        width: parent.width
                        text: catalog.i18nc("@label", "Update")
                        font: UM.Theme.getFont("medium_bold")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        showConfirmation("update")
                    }
                }

            }
            // Material warning message
            Rectangle {
                visible: device.materialWarning
                Layout.preferredWidth: Math.round(device.width - 65 - (UM.Theme.getSize("sidebar_item_margin").width * 2))
                Layout.minimumHeight: childrenRect.height
                Layout.alignment: Qt.AlignRight
                Layout.bottomMargin: Math.round(UM.Theme.getSize("sidebar_item_margin").height / 2)
                Layout.rightMargin: UM.Theme.getSize("sidebar_item_margin").width
                color: UM.Theme.getColor("sidebar_item_light")

                Text {
                    id: materialWarningIcon
                    font: UM.Theme.getFont("zaxe_icon_set")
                    color: UM.Theme.getColor("text_danger")
                    horizontalAlignment: Text.AlignLeft
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: "d"
                }
                Text {
                    width: parent.width
                    font: UM.Theme.getFont("medium")
                    color: UM.Theme.getColor("text_danger")
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                    anchors {
                        verticalCenter: materialWarningIcon.verticalCenter
                        left: materialWarningIcon.right
                        leftMargin: 1
                    }
                    text: catalog.i18nc("@warning", "The material in the device does not match with the material you choose. Please slice again with the correct material")
                }
            }

            // Model warning message
            Rectangle {
                visible: device.modelCompatibilityWarning
                Layout.preferredWidth: Math.round(device.width - 65 - (UM.Theme.getSize("sidebar_item_margin").width * 2))
                Layout.minimumHeight: 20
                Layout.alignment: Qt.AlignRight
                Layout.bottomMargin: Math.round(UM.Theme.getSize("sidebar_item_margin").height / 2)
                Layout.rightMargin: UM.Theme.getSize("sidebar_item_margin").width
                color: UM.Theme.getColor("sidebar_item_light")

                Text {
                    id: modelCompatibilityWarningIcon
                    font: UM.Theme.getFont("zaxe_icon_set")
                    color: UM.Theme.getColor("text_danger")
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                    }
                    text: "d"
                }
                Text {
                    width: parent.width
                    font: UM.Theme.getFont("medium")
                    color: UM.Theme.getColor("text_danger")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignLeft
                    anchors {
                        left: modelCompatibilityWarningIcon.right
                        leftMargin: 1
                        verticalCenter: modelCompatibilityWarningIcon.verticalCenter
                    }
                    text: catalog.i18nc("@warning", "This print is not compatible with this device model")
                }
            }

            // Third row - main
            Rectangle {
                id: containerExtraInfo
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: parent.width - 63
                Layout.preferredHeight: extraInfoColumn.height
                Layout.leftMargin: 60
                color: UM.Theme.getColor("sidebar_item_light")
                visible: false

                // Extra info column
                Rectangle {
                    width: parent.width; height: extraInfoColumn.height
                    anchors {
                        top: parent.top
                        topMargin: -3
                    }
                    color: UM.Theme.getColor("sidebar_item_light")

                    ColumnLayout {
                        id: extraInfoColumn
                        width: parent.width
                        spacing: 0

                        // Filename row
                        RowLayout {
                            visible: machineStates.printing
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: 30
                            Label {
                                text: "T"
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("zaxe_icon_set")
                                Layout.preferredHeight: 15
                                Layout.topMargin: -7
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Label {
                                text: device.printingFile
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("large_semi_bold")
                            }
                        }
                        // Bottom Border 
                        Rectangle { visible: machineStates.printing; Layout.leftMargin: 8; Layout.preferredWidth: parent.width; Layout.preferredHeight: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

                        // Duration row
                        RowLayout {
                            visible: machineStates.printing
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: 30
                            Label {
                                text: "V"
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("zaxe_icon_set")
                                Layout.preferredHeight: 15
                                Layout.topMargin: -7
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Label {
                                text: device.elapsedTimeTxt + " / " + device.estimatedTime
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("large_semi_bold")
                                Layout.preferredHeight: 15
                            }
                        }
                        // Bottom Border
                        Rectangle { visible: machineStates.printing; Layout.leftMargin: 8; Layout.preferredWidth: parent.width; Layout.preferredHeight: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

                        // Material and nozzle row
                        RowLayout {
                            Layout.preferredHeight: 30
                            Label {
                                text: "X"
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("zaxe_icon_set")
                                Layout.preferredHeight: 15
                                Layout.topMargin: -7
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Label {
                                text: networkMachineList.materialNames[device.material]
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("large_semi_bold")
                                Layout.preferredHeight: 15
                            }
                            Label {
                                text: "b"
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("zaxe_icon_set")
                                Layout.preferredHeight: 15
                                Layout.topMargin: -7
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Label {
                                text: device.nozzle + " mm"
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("large_semi_bold")
                                Layout.preferredHeight: 15
                            }
                        }
                        // Bottom Border 
                        Rectangle { Layout.leftMargin: 8; Layout.preferredWidth: parent.width; Layout.preferredHeight: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

                        // IP row
                        RowLayout {
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignTop
                            Label {
                                text: "c"
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("zaxe_icon_set")
                                Layout.preferredHeight: 15
                                Layout.topMargin: -7
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Label {
                                text: device.ip
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("large_semi_bold")
                                Layout.preferredHeight: 15
                            }
                        }
                        // Bottom Border
                        Rectangle { Layout.bottomMargin: 5; Layout.leftMargin: 8; Layout.preferredWidth: parent.width; Layout.preferredHeight: UM.Theme.getSize("default_lining").width; color: UM.Theme.getColor("sidebar_item_dark") }

                        // elapsed time calculation
                        Timer {
                            interval: 1000
                            running: machineStates.printing
                            repeat: true
                            onTriggered: {
                                device.elapsedTime = parseFloat(device.elapsedTime) + 1
                                elapsedTimeTxt = networkMachineList.toHHMMSS(device.elapsedTime)
                            }
                        }
                    }
                }
            } // End of Second row - main
        } // End of Main layout
    }
    // Bottom Border
    Rectangle {
        width: parent.width
        height: UM.Theme.getSize("default_lining").width
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        color: UM.Theme.getColor("sidebar_item_dark")
        z: 1
    }
}

