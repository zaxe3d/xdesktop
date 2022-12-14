// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Item {
    id: base

    signal showFirstrunTip(point position, string title, string text, bool nextAvailable, bool imgPath)

    UM.I18nCatalog { id: catalog; name:"cura"}

    property real progress: UM.Backend.progress
    property int backendState: UM.Backend.state
    property bool activity: CuraApplication.platformActivity
    // For now only lite series, those have gcode compatibility
    property string preferredMimeTypes: Cura.MachineManager.activeMachine.preferred_output_file_formats
    property bool isGCode: preferredMimeTypes.indexOf("gcode") > -1

    property variant printDuration: PrintInformation.currentPrintTime
    property variant printMaterialLengths: PrintInformation.materialLengths
    property variant printMaterialWeights: PrintInformation.materialWeights
    property variant printMaterialCosts: PrintInformation.materialCosts
    property variant printMaterialNames: PrintInformation.materialNames

    property string mWeight
    property string mLength
    width: parent.width

    function createManualMachine() {
        if (!inputIPAddress.acceptableInput) {
            return;
        }
        var customIPsPref = UM.Preferences.getValue("misc/custom_ips")
        var customIPs = customIPsPref == "" ? [] : customIPsPref.split("|")
        var ip = inputIPAddress.text
        if (customIPs.indexOf(ip) == -1) {
            customIPs.unshift(ip)
            customIPModel.insert(0, {"ip": ip});
            UM.Preferences.setValue("misc/custom_ips", customIPs.join("|"))
            Cura.NetworkMachineManager.CreateManualMachine(ip)
        }
        inputIPAddress.text = ""
    }

    Connections {
        target: PrintInformation

        onPreSlicedChanged: {
            if (PrintInformation.preSliced) {
                var info = PrintInformation.preSlicedInfo
                if (isGCode) { // We don't have presliced info for gcode
                    lblFilename.text = PrintInformation.baseName + ".gcode"
                    lblDuration.text = lblLength.text = lblMaterial.text = "-"
                } else {
                    var material = networkMachineList.materialNames[info.material]
                    lblMaterial.text = material.brand + (material.description ? " " + material.description : "")
                    lblFilename.text = PrintInformation.baseName + ".zaxe"
                    lblDuration.text = info.duration
                    lblLength.text = (info.filament_used / 1000) + "m."
                }

                if (info.material == undefined) {
                    lblWeight.text = "-"
                } else if (info.material == "zaxe_abs" || info.material == "zaxe_pla" || info.material.indexOf("zaxe_flex") > -1) {
                    lblWeight.text = (info.filament_used / 10 *
                                     (info.material == "zaxe_pla" ? 1.21 : 1.10) *
                                     Math.PI * Math.pow(0.175 / 2, 2) ).toFixed(2) + "gr."
                } else {
                    lblWeight.text = "-"
                }
            }
        }
    }

    onActivityChanged: {
        if (activity == false) {
            //When there is no mesh in the buildplate; the printJobTextField is set to an empty string so it doesn't set an     empty string as a jobName (which is later used for saving the file)
             PrintInformation.baseName = ''
        }
    }

    height: {
        // FIXME
        // if i use childrenRect.height it counts invisible maximum height??!
        if (itemLoadOrSlice.visible)
            return itemLoadOrSlice.height + itemMachineCourse.height
        else if (itemPrintDetails.visible)
            return itemPrintDetails.height + itemMachineCourse.height
        else if (itemSlicing.visible)
            return itemSlicing.height
    }

    Connections {
        target: UM.Preferences
        onPreferenceChanged:
        {
            if (UM.Preferences.getValue("general/firstrun")) {
                switch(UM.Preferences.getValue("general/firstrun_step")) {
                    case 3:
                        base.showFirstrunTip(
                            machineCarousel.mapToItem(base, 0, Math.round(machineCarousel.height / 2)),
                            catalog.i18nc("@firstrun", "Model Selection"),
                            catalog.i18nc("@firstrun", "Select Zaxe model you are using"), true, "")
                        break
                    case 4:
                        base.showFirstrunTip(
                            btnPrepare.mapToItem(base, 0, 5),
                            catalog.i18nc("@firstrun", "Prepare Model for Print"),
                            catalog.i18nc("@firstrun", "Set slicing options and slice your model"), false, "")
                        break
                    case 7:
                        if (Cura.NetworkMachineListModel.rowCount() == 0) {
                            UM.Preferences.setValue("general/firstrun_step", 8)
                        } else {
                            base.showFirstrunTip(
                                titleText.mapToItem(base, 0, 75),
                                catalog.i18nc("@firstrun", "Print It on Your Zaxe"),
                                catalog.i18nc("@firstrun", "Hit the Print Now! button on your Zaxe!"), false, "")
                        }
                        break
                    case 8:
                        base.showFirstrunTip(
                            saveToDisk.mapToItem(base, 0, 5),
                            catalog.i18nc("@firstrun", "Save to Flash Disk"),
                            catalog.i18nc("@firstrun", "Save your Zaxe file to your flash disk and print it on your Zaxe"), false, "")
                        break
                }
            }
        }
    }

    Rectangle {
        id: itemCustomIP
        z: 2
        visible: false
        color: UM.Theme.getColor("sidebar_item_medium_dark")
        anchors { top: parent.top; bottom: itemMachineCourse.top; left: parent.left; right: parent.right }

        ColumnLayout {
            spacing: 0
            width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
            anchors {
                top: parent.top
                topMargin: 25
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 15
            }

            // Title row
            RowLayout {
                Layout.preferredHeight: 20
                Button {
                    Layout.preferredHeight: 20
                    background: Rectangle {
                        color: UM.Theme.getColor("sidebar_item_medium_dark")
                    }
                    contentItem: Text {
                        color: UM.Theme.getColor("text_sidebar_dark")
                        text: catalog.i18nc("@label", "<")
                        font: UM.Theme.getFont("large_semi_bold")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        padding: 4
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    onClicked: {
                        itemCustomIP.visible = false
                        itemCustomIP.enabled = false
                        itemLoadOrSlice.enabled = true
                    }
                }
                Text {
                    text: catalog.i18nc("@label", "Custom IP")
                    color: UM.Theme.getColor("text_sidebar_dark")
                    width: parent.width
                    font: UM.Theme.getFont("large")
                    horizontalAlignment: Text.AlignHCenter
                    padding: 4
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
            }
            // Bottom Border
            Rectangle { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: parent.width - UM.Theme.getSize("sidebar_item_margin").width; Layout.preferredHeight: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }
            ListModel {
                id: customIPModel
            }

            Component {
                id: customIPDelegate
                Item {
                    width: 270; height: 25
                    Row {
                        Text { width: 250; height: 20; text: ip; font: UM.Theme.getFont("default"); renderType: Text.NativeRendering } // M1 Mac garbled text fix
                        Button {
                            implicitWidth: 20; implicitHeight: 20
                            background: Rectangle {
                                color: UM.Theme.getColor("button_danger")
                                radius: 5
                            }
                            contentItem: Text {
                                color: UM.Theme.getColor("text_white")
                                font: UM.Theme.getFont("zaxe_icon_set_small")
                                text: "a"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: {
                                var customIPsPref = UM.Preferences.getValue("misc/custom_ips")
                                var customIPs = customIPsPref == "" ? [] : customIPsPref.split("|")
                                var idx = customIPs.indexOf(ip)
                                if (idx > -1) {
                                    Cura.NetworkMachineManager.RemoveManualMachine(customIPs[idx])
                                    customIPs.splice(idx, 1)
                                    customIPModel.remove(idx, 1);
                                    UM.Preferences.setValue("misc/custom_ips", customIPs.join("|"))
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                id: listView
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: UM.Theme.getSize("sidebar_item_margin").height
                Layout.preferredHeight: 90
                Layout.preferredWidth: 280
                ScrollBar.vertical: ScrollBar {}
                model: customIPModel
                delegate: customIPDelegate
                Component.onCompleted: {
                    var customIPsPref = UM.Preferences.getValue("misc/custom_ips")
                    var customIPs = customIPsPref == "" ? [] : customIPsPref.split("|")
                    for (var i in customIPs) {
                        customIPModel.append({"ip": customIPs[i]});
                        Cura.NetworkMachineManager.CreateManualMachine(customIPs[i])
                    }
                }
            }

            RowLayout {
                Layout.preferredWidth: 235; Layout.preferredHeight: 30
                Layout.alignment: Qt.AlignHCenter

                TextField {
                    id: inputIPAddress
                    placeholderText: catalog.i18nc("@label", "Enter an IP address...")

                    selectByMouse: true
                    font: UM.Theme.getFont("medium")
                    color: UM.Theme.getColor("text_sidebar")
                    padding: 0
                    Layout.preferredWidth: 235; Layout.preferredHeight: 30
                    validator: RegExpValidator {
                        regExp:  /^\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b$/
                    }

                    background: Rectangle {
                        color: UM.Theme.getColor("sidebar_item_medium_dark")
                        border.width: 0
                        radius: 2
                        // Bottom border only
                        Rectangle { width: parent.width; height: UM.Theme.getSize("default_lining").height; anchors.bottom: parent.bottom; anchors.bottomMargin: UM.Theme.getSize("default_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }
                    }
                    Keys.onPressed: {
                        if (event.key == Qt.Key_Escape) {
                            inputIPAddress.text = "";
                            event.accepted = true;
                        }
                    }
                    onAccepted: {
                        createManualMachine()
                    }
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }

                Button {
                    Layout.preferredHeight: 27
                    background: Rectangle {
                        color: UM.Theme.getColor("button_blue")
                        radius: 10
                    }
                    contentItem: Text {
                        color: UM.Theme.getColor("text_white")
                        width: parent.width
                        text: catalog.i18nc("@label", "+ Add")
                        font: UM.Theme.getFont("medium_bold")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    onClicked: createManualMachine()
                }
            }
        }
    }

    Rectangle {
        // 1 = ready to slice 4 = unable to slice
        id: itemLoadOrSlice
        visible: base.backendState != "undefined" && (base.backendState == 1 || base.backendState == 4) || !activity
        height: childrenRect.height + 20 + 25
        color: UM.Theme.getColor("sidebar_item_medium_dark")
        width: parent.width
        anchors.top: parent.top; anchors.left: parent.left
        ColumnLayout {
            spacing: 2
            width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
            anchors {
                top: parent.top
                topMargin: 20
                bottomMargin: 15
            }

            // Title row
            Text {
                text: catalog.i18nc("@label", "Zaxe model you are using")
                color: UM.Theme.getColor("text_sidebar")
                font: UM.Theme.getFont("extra_large_bold")
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 25
                renderType: Text.NativeRendering // M1 Mac garbled text fix
            }

            RowLayout {
                id: machineCarousel
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.preferredHeight: 80
                Layout.leftMargin: 10

                MachineCarousel { modelName: "X1"; modelId: "zaxe_x1"; Layout.preferredWidth: 30; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "X1+"; modelId: "zaxe_x1+"; Layout.preferredWidth: 37; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "X2"; modelId: "zaxe_x2"; Layout.preferredWidth: 28; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "X3"; modelId: "zaxe_x3"; Layout.preferredWidth: 30; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "XLite"; modelId: "zaxe_xlite"; Layout.preferredWidth: 27; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "Z1"; modelId: "zaxe_z1"; Layout.preferredWidth: 35; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "Z1+"; modelId: "zaxe_z1+"; Layout.preferredWidth: 39; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "Z2"; modelId: "zaxe_z2"; Layout.preferredWidth: 37; Layout.preferredHeight: 60 }
                MachineCarousel { modelName: "Z3"; modelId: "zaxe_z3"; Layout.preferredWidth: 40; Layout.preferredHeight: 60 }
                //MachineCarousel { modelName: "Z3+"; modelId: "zaxe_z3+"; Layout.preferredWidth: 49; Layout.preferredHeight: 60 }
            }

            Button {
                id: btnPrepare
                Layout.preferredWidth: 230
                Layout.preferredHeight: 32
                Layout.topMargin: 20
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                background: Rectangle {
                    color: UM.Theme.getColor("button_blue")
                    radius: 10
                }
                contentItem: Text {
                    color: "white"
                    text: {
                        if (!activity) {
                            return catalog.i18nc("@label", "Click to load a 3D model")
                        }
                        else {
                            return catalog.i18nc("@label", "Prepare model for print")
                        }
                    }
                    font: UM.Theme.getFont("medium");
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
                onClicked: {
                    if (!activity) {
                        Cura.Actions.open.trigger()
                    } else {
                        UM.Controller.setActiveStage("PrepareStage")
                        Cura.Actions.clearSelection.trigger()

                        if (UM.Preferences.getValue("general/firstrun"))
                            UM.Preferences.setValue("general/firstrun_step", 5)
                    }
                }
            }
        }
    }

    // Print details pane
    Rectangle {
        // 3 = done, 5 = disabled
        // Show print details when slicing is done.
        id: itemPrintDetails
        visible: base.backendState != "undefined" && (base.backendState == 3 || base.backendState == 5)
        height: childrenRect.height + 30 // doesn't count margin as childrenRect.height
        width: parent.width
        color: UM.Theme.getColor("sidebar_item_medium_dark")

        Column {
            spacing: 0
            width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
            anchors {
                top: parent.top
                topMargin: 20
                horizontalCenter: parent.horizontalCenter
            }

            // Title row
            Text {
                id: lblPrintDetails
                text: catalog.i18nc("@label", "Print details")
                color: UM.Theme.getColor("text_sidebar")
                width: parent.width
                font: UM.Theme.getFont("large")
                padding: 10
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering // M1 Mac garbled text fix
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            // File name row
            Item {
                width: parent.width
                height: 32
                RowLayout {
                    Label {
                        text: "T"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.topMargin: -5
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    TextField {
                        id: inputFilename
                        visible: false
                        selectByMouse: true
                        color: UM.Theme.getColor("text_sidebar_dark")
                        font: UM.Theme.getFont("large")
                        text: lblFilename.text
                        padding: 0
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.topMargin: 0
                        Layout.leftMargin: -5

                        background: Rectangle {
                            color: UM.Theme.getColor("sidebar_item_medium_dark")
                            border.width: 0
                            radius: 2
                        }

                        Keys.onPressed: {
                            if (event.key == Qt.Key_Escape) {
                                inputFilename.text = "";
                                event.accepted = true;
                            } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                                PrintInformation.setBaseNameDirect(inputFilename.text)
                                lblFilename.text = PrintInformation.baseName + (isGCode ? ".gcode" : ".zaxe");
                                inputFilename.visible = false;
                                lblFilename.visible = true;
                                event.accepted = true;
                            }
                        }
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    // device name label
                    Label {
                        id: lblFilename
                        Layout.preferredHeight: 32
                        text: PrintInformation.baseName + (isGCode ? ".gcode" : ".zaxe")
                        color: UM.Theme.getColor("text_sidebar_dark")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        clip: true
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                inputFilename.text = lblFilename.text.replace(".zaxe", "").replace(".gcode", "")
                                lblFilename.visible = false
                                inputFilename.visible = true
                                inputFilename.focus = true
                            }
                        }
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            // Duration row
            Item {
                width: parent.width
                height: 32
                RowLayout {
                    Label {
                        text: "V"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.topMargin: -5
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    Text {
                        id: lblDuration
                        text: (!base.printDuration || !base.printDuration.valid) ? catalog.i18nc("@label Hours and minutes", "00h 00min") : base.printDuration.getDisplayString(UM.DurationFormat.ISO8601)
                        color: UM.Theme.getColor("text_sidebar_dark")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.preferredHeight: 32
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            // Details row (weight - length - material
            Item {
                width: parent.width
                height: 32
                RowLayout {
                    Label {
                        text: "U"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.topMargin: -5
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    Label {
                        id: lblWeight
                        text: {
                            var lengths = [];
                            var weights = [];
                            if(base.printMaterialLengths) {
                                for(var index = 0; index < base.printMaterialLengths.length; index++)
                                {
                                    if(base.printMaterialLengths[index] > 0)
                                    {
                                        lengths.push(base.printMaterialLengths[index].toFixed(2));
                                        weights.push(String(Math.round(base.printMaterialWeights[index])));
                                        var cost = base.printMaterialCosts[index] == undefined ? 0 : base.printMaterialCosts[index].toFixed(2);
                                    }
                                }
                            }
                            if(lengths.length == 0)
                            {
                                lengths = ["0.00"];
                                weights = ["0"];
                            }
                            base.mWeight = weights.join(" + ") + "gr.";
                            base.mLength = lengths.join(" + ") + "m.";
                            return base.mWeight
                        }
                        color: UM.Theme.getColor("text_sidebar_dark")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.preferredHeight: 32
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    Label {
                        text: "W"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.topMargin: -5
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    Text {
                        id: lblLength
                        text: base.mLength
                        color: UM.Theme.getColor("text_sidebar_dark")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.preferredHeight: 32
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    Label {
                        text: "X"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        Layout.topMargin: -5
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                    Text {
                        id: lblMaterial
                        text: {
                            if (PrintInformation.materialNames[0]) {
                                var material = networkMachineList.materialNames[PrintInformation.materialNames[0]]
                                return material.brand + (material.description ? " " + material.description : "")
                            }
                            return ""
                        }
                        color: UM.Theme.getColor("text_sidebar_dark")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.preferredHeight: 32
                        renderType: Text.NativeRendering // M1 Mac garbled text fix
                    }
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            // Button row
            Item {
                width: parent.width
                height: 77
                RowLayout {
                    anchors { verticalCenter: parent.verticalCenter }
                    height: 25
                    Button {
                        id: saveToDisk
                        background: Rectangle {
                            color: UM.Theme.getColor("button_blue")
                            radius: 10
                        }
                        contentItem: Text {
                            color: UM.Theme.getColor("text_white")
                            text: catalog.i18nc("@label", "Save to flash disk")
                            font: UM.Theme.getFont("medium")
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            padding: 4
                            renderType: Text.NativeRendering // M1 Mac garbled text fix
                        }
                        onClicked: {
                            UM.Preferences.setValue("general/firstrun_step", 9)
                            UM.OutputDeviceManager.requestWriteToDevice(
                                UM.OutputDeviceManager.activeDevice,
                                (Cura.MachineManager.activeMachineId.search("XLite|X3") == 0 ? PrintInformation.simpleBaseName : PrintInformation.detailedBaseName),
                                { "filter_by_machine": true, "preferred_mimetypes": preferredMimeTypes }
                            )
                        }
                    }
                    Button {
                        id: cancel
                        background: Rectangle {
                            color: UM.Theme.getColor("button_gray")
                            border.color: UM.Theme.getColor("text_danger")
                            border.width: UM.Theme.getSize("default_lining").width
                            radius: 10
                        }
                        contentItem: Text {
                            color: UM.Theme.getColor("text_danger")
                            text: catalog.i18nc("@label", "Cancel")
                            font: UM.Theme.getFont("medium")
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            padding: 4
                            renderType: Text.NativeRendering // M1 Mac garbled text fix
                        }
                        onClicked: {
                            if (base.backendState == 5) { // slicing unavailable
                                CuraApplication.deleteAll()
                            } else {
                                CuraApplication.backend.stopSlicing();
                            }
                            UM.Controller.setActiveView("SolidView")

                            if (UM.Preferences.getValue("general/firstrun"))
                                UM.Preferences.setValue("general/firstrun_step", 4)
                        }
                    }
                }
            }
        }
    }

    // Machine course
    Rectangle {
        id: itemMachineCourse
        height: 43
        width: parent.width
        color: UM.Theme.getColor("sidebar_item_light")
        anchors.bottom: parent.bottom

        // Title row
        Text {
            id: titleText
            text: catalog.i18nc("@label", "Machine course")
            color: UM.Theme.getColor("text_sidebar")
            width: parent.width
            font: UM.Theme.getFont("extra_large_bold")
            horizontalAlignment: Text.AlignHCenter
            padding: 10
            anchors { bottom: parent.bottom; bottomMargin: -UM.Theme.getSize("default_lining").height }
            renderType: Text.NativeRendering // M1 Mac garbled text fix
        }

        Button {
            anchors { right: parent.right; verticalCenter: titleText.verticalCenter }
            background: Rectangle {
                color: UM.Theme.getColor("sidebar_item_light")
            }
            contentItem: Text {
                color: UM.Theme.getColor("text_sidebar_medium")
                text: catalog.i18nc("@label", "Custom IP...")
                font: UM.Theme.getFont("medium")
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                padding: 4
                renderType: Text.NativeRendering // M1 Mac garbled text fix
            }
            onClicked: {
                itemCustomIP.enabled = true
                itemLoadOrSlice.enabled = false
                itemCustomIP.visible = true
            }
        }
    }


    Item {
        // 2 = slicing
        // Show slicing progress here
        id: itemSlicing
        visible: base.backendState != "undefined" && base.backendState == 2
        height: childrenRect.height + 50
        width: base.width - 10
        anchors {
            top: parent.top; left: parent.left
            topMargin: 20; leftMargin: 15
        }
        Column {
            spacing: UM.Theme.getSize("sidebar_item_margin").height
            width: parent.width
            Layout.leftMargin: 50
            Text {
                text: catalog.i18nc("@label", "Preparing...")
                color: UM.Theme.getColor("text_sidebar")
                font: UM.Theme.getFont("large")
                renderType: Text.NativeRendering // M1 Mac garbled text fix
            }
            Label {
                width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
                font: UM.Theme.getFont("large")
                color: UM.Theme.getColor("text_sidebar")
                horizontalAlignment: Text.AlignRight
                text: parseInt(base.progress * 100, 10) + "%"
                renderType: Text.NativeRendering // M1 Mac garbled text fix
            }
            Rectangle {
                id: progressBar
                width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
                height: UM.Theme.getSize("progressbar").height
                radius: UM.Theme.getSize("progressbar_radius").width
                color: UM.Theme.getColor("progressbar_background")

                Rectangle {
                    width: Math.max(parent.width * base.progress)
                    height: parent.height
                    radius: UM.Theme.getSize("progressbar_radius").width
                    color: UM.Theme.getColor("text_blue")
                }
            }
            Button {
                id: cancelProgress
                background: Rectangle {
                    color: UM.Theme.getColor("button_gray")
                    border.color: UM.Theme.getColor("text_danger")
                    border.width: UM.Theme.getSize("default_lining").width
                    radius: 10
                }
                contentItem: Text {
                    color: UM.Theme.getColor("text_danger")
                    text: catalog.i18nc("@label", "Cancel")
                    font: UM.Theme.getFont("medium")
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    padding: 4
                    renderType: Text.NativeRendering // M1 Mac garbled text fix
                }
                onClicked: {
                    CuraApplication.backend.stopSlicing();
                    UM.Controller.setActiveView("SolidView")
                    if (UM.Preferences.getValue("general/firstrun"))
                        UM.Preferences.setValue("general/firstrun_step", 4)
                }
            }
        }
    }

}
