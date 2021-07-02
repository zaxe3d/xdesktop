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
    property string  fwVersion
    property string printingFile
    property var startTime
    property string elapsedTimeTxt
    property string estimatedTime
    property string snapshot
    property string filamentColor
    property bool hasSnapshot
    property bool hasPin
    property bool hasNFCSpool
    property bool hasFWUpdate
    property var progress: 0
    property var filamentRemaining: 0

    property var pausedSeconds: 0

    property bool canceling

    // states
    property var machineStates

    // warnings
    property bool nozzleWarning
    property bool materialWarning
    property bool filamentLengthWarning
    property bool modelCompatibilityWarning

    property string nextState

    property bool isLite

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
            startTime= parseFloat(arguments[2]) // reset the timer as well
            estimatedTime = arguments[3]
            imgSnapshot.sourceChanged()
            pausedSeconds = 0
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
            if (machineStates.calibrating || machineStates.uploading) return
            progress = arguments[1]
        }
        onCalibrationProgress: {
            if (uid != arguments[0]) return
            progress = arguments[1]
        }
        onPinChange: {
            if (uid != arguments[0]) return
            hasPin = arguments[1]
        }
        onSpoolChange: {
            if (uid != arguments[0]) return
            hasNFCSpool = arguments[1]
            filamentRemaining = arguments[2]
            filamentColor = arguments[3]
        }
        onUploadProgress: {
            if (uid != arguments[0]) return
            progress = arguments[1]
        }
        onStateChange: {
            if (uid != arguments[0]) return
            machineStates = arguments[1]
            if (!machineStates.paused) {
                progress = 0 // new state new bar
            }
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
        inputPinCode.focus = true
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
            case "filament_unload":
                Cura.NetworkMachineManager.FilamentUnload(device.uid)
                break;
        }
        device.nextState = ""
        confirmationPane.visible = false
        device.filamentLengthWarning = false
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
                    Layout.preferredWidth: 212; Layout.preferredHeight: 30
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
                    Layout.preferredWidth: 63
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
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
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

                            MouseArea {
                                id: mouseAreaSnapshot
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: {
                                    if (imgLive.visible)
                                        networkMachineList.showPopup(device.name, "ftp://" + device.ip + ":9494/snapshot.jpg")
                                }
                                onHoveredChanged: {
                                     printerIcon.visible = containsMouse
                                        ? true
                                        : printerIcon.isVisible
                                }
                            }

                            Image {
                                id: imgSnapshot
                                anchors.centerIn: parent
                                visible: !machineStates.calibrating && (machineStates.bed_occupied || machineStates.printing || machineStates.heating) && device.hasSnapshot
                                onVisibleChanged: { printerIcon.visible = !visible }
                                source: visible ? device.snapshot : ""
                                cache: false
                                width: 60
                                height: width
                            }

                            Image {
                                id: imgLive
                                anchors {
                                    right: parent.right
                                    bottom: parent.bottom
                                    bottomMargin: 2
                                    rightMargin: 2
                                }
                                visible: device.snapshot && fwVersion.split(".")[2] >= 95
                                source: visible ? "../images/live.png" : ""
                                width: 12
                                height: 12
                                antialiasing: true
                            }

                            Text {
                                id: printerIcon
                                property bool isVisible : !imgSnapshot.visible && imgSnapshot.progress != 1
                                anchors.centerIn: parent
                                visible: isVisible
                                font: UM.Theme.getFont("xx_large")
                                color: UM.Theme.getColor("text_sidebar_light")
                                text: device.deviceModel.replace("plus", "+").toUpperCase()
                                renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                                            lblDeviceName.visible = false
                                            inputDeviceName.visible = true
                                            inputDeviceName.focus = true
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
                                            renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                                            renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                                        visible: machineStates.paused && !machineStates.heating
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
                                            renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                                            text: catalog.i18nc("@button", "L")
                                            anchors.top: parent.top
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                                            renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                                            renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                                    visible: !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied && !machineStates.updating
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
                                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                                    }
                                    onClicked: {
                                        // check if the slice is ready or if there is a model
                                        if (PrintInformation.preSliced) {
                                            var info = PrintInformation.preSlicedInfo
                                            if (device.isLite) {
                                                Cura.NetworkMachineManager.upload(device.uid)
                                            } else if (!CuraApplication.platformActivity) {
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                shakeAnim.start()
                                            } else if (info.model != device.deviceModel.toUpperCase()) {
                                                device.modelCompatibilityWarning = true
                                                shakeAnim.start()
                                            } else if (info.material.indexOf(device.material) == -1) {
                                                device.materialWarning = true
                                                shakeAnim.start()
                                            } else {
                                                if (device.hasNFCSpool && device.filamentRemaining - (info.filament_used / 1000) <= 0) {
                                                    device.filamentLengthWarning = true
                                                } else {
                                                    device.filamentLengthWarning = false
                                                }
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                Cura.NetworkMachineManager.upload(device.uid) == false
                                            }
                                        } else {
                                            // 3 is Done
                                            if (UM.Backend.state != "undefined" && UM.Backend.state != 3 || !CuraApplication.platformActivity) {
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                device.filamentLengthWarning = false
                                                shakeAnim.start()
                                            } else if (Cura.MachineManager.activeMachineName.replace("+", "PLUS").toUpperCase() != device.deviceModel.toUpperCase()) {
                                                device.modelCompatibilityWarning = true
                                                shakeAnim.start()
                                            } else if (device.isLite) {
                                                // Light models doesn' care neithter about filament type nor nozzle type.
                                                Cura.NetworkMachineManager.upload(device.uid)
                                            } else if (Cura.MachineManager.activeVariantName != device.nozzle) {
                                                device.nozzleWarning = true
                                                shakeAnim.start()
                                            } else if (PrintInformation.materialNames[0].indexOf(device.material) == -1) {
                                                device.materialWarning = true
                                                shakeAnim.start()
                                            } else {
                                                if (device.hasNFCSpool && device.filamentRemaining - PrintInformation.materialLengths[0] <= 0) {
                                                    device.filamentLengthWarning = true
                                                } else {
                                                    device.filamentLengthWarning = false
                                                }
                                                device.nozzleWarning = false
                                                device.materialWarning = false
                                                device.modelCompatibilityWarning = false
                                                Cura.NetworkMachineManager.upload(device.uid)
                                            }
                                        }
                                        // final step for first-run
                                        if (UM.Preferences.getValue("general/firstrun"))
                                            UM.Preferences.setValue("general/firstrun_step", 9)
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
                                        else if (machineStates.calibrating)
                                            return catalog.i18nc("@label", "Calibrating...")
                                        else if (machineStates.heating)
                                            return catalog.i18nc("@label", "Heating...")
                                        else if (machineStates.paused)
                                            return catalog.i18nc("@label", "Paused")
                                        else if (machineStates.printing)
                                            return catalog.i18nc("@label", "Printing...")
                                        else if (machineStates.uploading)
                                            return catalog.i18nc("@label", "Uploading...")
                                        else if (machineStates.updating)
                                            return catalog.i18nc("@label", "Updating...")
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
                                    renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                visible: device.hasFWUpdate && !machineStates.updating
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
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
                Button {
                    id: btnfwUpdate
                    // only Z series has remote update
                    visible: deviceModel.search("z1") == 0 && !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied
                    Layout.preferredHeight: 27
                    anchors {
                        verticalCenter: fwUpdateMessage.verticalCenter
                        left: fwUpdateMessage.right
                        leftMargin: -8
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
                        font: UM.Theme.getFont("small_bold")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    onClicked: {
                        showConfirmation("update")
                    }
                }

            }
            // Nozzle warning message
            Rectangle {
                visible: device.nozzleWarning && Cura.MachineManager.activeVariantName != device.nozzle
                Layout.preferredWidth: Math.round(device.width - 65 - (UM.Theme.getSize("sidebar_item_margin").width * 2))
                Layout.minimumHeight: childrenRect.height
                Layout.alignment: Qt.AlignRight
                Layout.bottomMargin: Math.round(UM.Theme.getSize("sidebar_item_margin").height / 2)
                Layout.rightMargin: UM.Theme.getSize("sidebar_item_margin").width
                color: UM.Theme.getColor("sidebar_item_light")

                Text {
                    id: nozzleWarningIcon
                    font: UM.Theme.getFont("zaxe_icon_set")
                    color: UM.Theme.getColor("text_danger")
                    horizontalAlignment: Text.AlignLeft
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: "d"
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
                Text {
                    width: parent.width
                    font: UM.Theme.getFont("medium")
                    color: UM.Theme.getColor("text_danger")
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                    anchors {
                        verticalCenter: nozzleWarningIcon.verticalCenter
                        left: nozzleWarningIcon.right
                        leftMargin: 1
                    }
                    text: catalog.i18nc("@warning", "The nozzle [%1] currently installed on machine does not match with the Zaxe file [%2] Please slice again with the correct nozzle diameter [%1]").arg(device.nozzle).arg(Cura.MachineManager.activeVariantName)
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
            }

            // Material warning message
            Rectangle {
                visible: device.filamentLengthWarning
                Layout.preferredWidth: Math.round(device.width - 65 - (UM.Theme.getSize("sidebar_item_margin").width * 2))
                Layout.minimumHeight: childrenRect.height
                Layout.alignment: Qt.AlignRight
                Layout.bottomMargin: Math.round(UM.Theme.getSize("sidebar_item_margin").height / 2)
                Layout.rightMargin: UM.Theme.getSize("sidebar_item_margin").width
                color: UM.Theme.getColor("sidebar_item_light")

                Text {
                    id: filamentLengthWarningIcon
                    font: UM.Theme.getFont("zaxe_icon_set")
                    color: UM.Theme.getColor("text_danger")
                    horizontalAlignment: Text.AlignLeft
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    text: "d"
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
                Text {
                    width: parent.width
                    font: UM.Theme.getFont("medium")
                    color: UM.Theme.getColor("text_warning")
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                    anchors {
                        verticalCenter: filamentLengthWarningIcon.verticalCenter
                        left: filamentLengthWarningIcon.right
                        leftMargin: 1
                    }
                    text: catalog.i18nc("@warning", "Remaining filament on device may not be enough for this print.")
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
            }

            // Material warning message
            Rectangle {
                visible: device.materialWarning && PrintInformation.materialNames[0] != device.material
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
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
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
                            Item {
                                property string text: device.printingFile
                                property string spacing: "      "
                                property string combined: text + spacing
                                property string display: combined.substring(step) + combined.substring(0, step)
                                property int step: 0
                                Layout.preferredHeight: parent.height
                                Timer {
                                    interval: 250
                                    running: parent.visible && parent.text.length > 35
                                    repeat: true
                                    onTriggered: parent.step = (parent.step + 1) % parent.combined.length
                                }
                                Text {
                                    width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
                                    height: parent.height
                                    verticalAlignment: Text.AlignVCenter
                                    color: UM.Theme.getColor("text_sidebar_medium")
                                    font: UM.Theme.getFont("large_semi_bold")
                                    text: parent.display
                                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                                }
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
                                text: {
                                    if (device.isLite) {
                                        return "-"
                                    } else if (device.hasNFCSpool) {
                                        var colorUpper = device.filamentColor.charAt(0).toUpperCase() +
                                                         device.filamentColor.slice(1)
                                        var color = networkMachineList.materialColors[colorUpper]
                                        return color + " " +
                                               networkMachineList.materialNames[device.material] +
                                               " ~" + device.filamentRemaining + "m"
                                    } else {
                                        return networkMachineList.materialNames[device.material]
                                    }
                                }
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("large_semi_bold")
                                Layout.preferredHeight: device.hasNFCSpool ? 20 : 15 // ?!
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
                                text: device.isLite ? "-" : device.nozzle + " mm"
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("large_semi_bold")
                                Layout.preferredHeight: 15
                            }

                            Button {
                                id: btnFilamentUnload
                                // only Z series has remote update
                                visible: deviceModel.search("z1") == 0 && fwVersion.split(".")[2] >= 76 && !machineStates.paused && !machineStates.printing && !machineStates.uploading && !machineStates.heating && !canceling && !machineStates.calibrating && !machineStates.bed_occupied
                                Layout.preferredHeight: parent.height / 2
                                background: Rectangle {
                                    color: UM.Theme.getColor("button_blue")
                                    border.color: UM.Theme.getColor("button_blue")
                                    border.width: UM.Theme.getSize("default_lining").width
                                    radius: 10
                                }
                                contentItem: Text {
                                    color: UM.Theme.getColor("text_white")
                                    width: parent.width
                                    text: catalog.i18nc("@label", "Unload")
                                    font: UM.Theme.getFont("small_bold")
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                                }
                                onClicked: {
                                    showConfirmation("filament_unload")
                                }
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
                                Layout.preferredWidth: 130
                            }
                            Label {
                                text: "v" + device.fwVersion
                                color: UM.Theme.getColor("text_sidebar_medium")
                                font: UM.Theme.getFont("small")
                                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                                Layout.leftMargin: 135
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
                                elapsedTimeTxt = networkMachineList.toHHMMSS(
                                    // get time in unix time
                                    Math.floor(Date.now() / 1000) -
                                    // subtract the start time as we proceed
                                    parseFloat(device.startTime) -
                                    // below line enables us to pause timer when device is paused
                                    (machineStates.paused ? device.pausedSeconds++ : device.pausedSeconds)
                                )
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

