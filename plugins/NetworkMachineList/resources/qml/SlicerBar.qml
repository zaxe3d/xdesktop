// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import UM 1.1 as UM
import Cura 1.0 as Cura

Item {
    id: base
    UM.I18nCatalog { id: catalog; name:"cura"}

    property real progress: UM.Backend.progress
    property int backendState: UM.Backend.state
    property bool activity: CuraApplication.platformActivity

    property variant printDuration: PrintInformation.currentPrintTime
    property variant printMaterialLengths: PrintInformation.materialLengths
    property variant printMaterialWeights: PrintInformation.materialWeights
    property variant printMaterialCosts: PrintInformation.materialCosts
    property variant printMaterialNames: PrintInformation.materialNames

    property string fileBaseName: PrintInformation.baseName
    property string mWeight
    property string mLength
    width: parent.width

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
            return itemLoadOrSlice.height + itemMachineCourse.height + 10
        else if (itemPrintDetails.visible)
            return itemPrintDetails.height + itemMachineCourse.height + 10
        else if (itemSlicing.visible)
            return itemSlicing.height + 10
    }

    Connections {
        target: CuraApplication
    }

    Rectangle {
        // 1 = ready to slice
        id: itemLoadOrSlice
        visible: base.backendState != "undefined" && base.backendState == 1 || !activity
        height: childrenRect.height + 45 + 25
        color: UM.Theme.getColor("sidebar_item_medium_dark")
        width: parent.width
        anchors.top: parent.top; anchors.left: parent.left
        ColumnLayout {
            spacing: 2
            width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
            anchors {
                top: parent.top
                topMargin: 45
                bottomMargin: 25
            }

            // Title row
            Text {
                text: catalog.i18nc("@label", "Zaxe model you are using")
                color: UM.Theme.getColor("text_sidebar")
                font: UM.Theme.getFont("extra_large_bold")
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.preferredHeight: 180

                MachineCarousel { modelName: "X1"; modelId: "zaxe_x1"; Layout.preferredWidth: 85; Layout.preferredHeight: 80 }
                MachineCarousel { modelName: "X1+"; modelId: "zaxe_x1+"; Layout.preferredWidth: 85; Layout.preferredHeight: 80 }
                MachineCarousel { modelName: "Z1"; modelId: "zaxe_z1"; enabled: false; Layout.preferredWidth: 85; Layout.preferredHeight: 80 }
                MachineCarousel { modelName: "Z1+"; modelId: "zaxe_z1+"; enabled: false; Layout.preferredWidth: 85; Layout.preferredHeight: 80 }
            }

            Button {
                id: btnPrepare
                Layout.preferredWidth: 250
                Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignHCenter
                background: Rectangle {
                    color: UM.Theme.getColor("button_blue")
                    radius: 10
                }
                contentItem: Text {
                    color: "white"
                    width: parent.width
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
                }
                onClicked: {
                    if (!activity) {
                        Cura.Actions.open.trigger()
                    } else {
                        UM.Controller.setActiveStage("PrepareStage")
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
        height: childrenRect.height + 45 // doesn't count margin as childrenRect.height
        width: parent.width
        color: UM.Theme.getColor("sidebar_item_medium_dark")

        Column {
            spacing: 7
            width: parent.width - UM.Theme.getSize("sidebar_item_margin").width
            anchors {
                top: parent.top
                topMargin: 45
                horizontalCenter: parent.horizontalCenter
            }

            // Title row
            Text {
                id: lblPrintDetails
                text: catalog.i18nc("@label", "Print details")
                color: UM.Theme.getColor("text_sidebar_medium")
                width: parent.width
                font: UM.Theme.getFont("xx_large")
                horizontalAlignment: Text.AlignHCenter
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            // File name row
            Item {
                width: parent.width
                height: 40
                RowLayout {
                    Label {
                        text: "T"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: base.fileBaseName + ".zaxe"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("large")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.bottomMargin: 7
                    }
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            // Duration row
            Item {
                width: parent.width
                height: 40
                RowLayout {
                    Label {
                        text: "V"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: (!base.printDuration || !base.printDuration.valid) ? catalog.i18nc("@label Hours and minutes", "00h 00min") : base.printDuration.getDisplayString(UM.DurationFormat.Short)
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.bottomMargin: 7
                    }
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            // Details row (weight - length - material
            Item {
                width: parent.width
                height: 40
                RowLayout {
                    Label {
                        text: "U"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Label {
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
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.bottomMargin: 7
                    }
                    Label {
                        text: "W"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: base.mLength
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.bottomMargin: 7
                    }
                    Label {
                        text: "X"
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("zaxe_icon_set")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    }
                    Text {
                        text: PrintInformation.materialNames[0] ? networkMachineList.materialNames[PrintInformation.materialNames[0]] : ""
                        color: UM.Theme.getColor("text_sidebar")
                        font: UM.Theme.getFont("large_nonbold")
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        Layout.bottomMargin: 7
                    }
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            // Button row
            Item {
                width: parent.width
                height: 70
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    height: 70
                    Button {
                        id: saveToDisk
                        background: Rectangle {
                            color: UM.Theme.getColor("button_blue")
                            radius: 10
                        }
                        contentItem: Text {
                            color: UM.Theme.getColor("text_white")
                            text: catalog.i18nc("@label", "Save to flash disk")
                            font: UM.Theme.getFont("large_nonbold")
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            padding: 5
                        }
                        onClicked: {
                            UM.OutputDeviceManager.requestWriteToDevice(UM.OutputDeviceManager.activeDevice, PrintInformation.jobName,
                                { "filter_by_machine": true, "preferred_mimetypes": Cura.MachineManager.activeMachine.preferred_output_file_formats });
                        }
                    }
                    Button {
                        id: cancel
                        background: Rectangle {
                            color: UM.Theme.getColor("button_gray")
                            border.color: UM.Theme.getColor("text_danger")
                            border.width: 2
                            radius: 10
                        }
                        contentItem: Text {
                            color: UM.Theme.getColor("text_danger")
                            text: catalog.i18nc("@label", "Cancel")
                            font: UM.Theme.getFont("large_nonbold")
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            padding: 5
                        }
                        onClicked: {
                            CuraApplication.backend.stopSlicing();
                            UM.Controller.setActiveView("SolidView")
                        }
                    }
                }
            }
        }
    }

    // Machine course
    Rectangle {
        id: itemMachineCourse
        height: 45
        width: parent.width
        color: UM.Theme.getColor("sidebar_item_light")
        anchors.bottom: parent.bottom

        // Title row
        Text {
            text: catalog.i18nc("@label", "Machine course")
            color: UM.Theme.getColor("text_sidebar_medium")
            width: parent.width
            font: UM.Theme.getFont("xx_large")
            horizontalAlignment: Text.AlignHCenter
            padding: 10
            anchors.bottom: parent.bottom
        }
    }


    Item {
        // 2 = slicing
        // Show slicing progress here
        id: itemSlicing
        visible: base.backendState != "undefined" && base.backendState == 2
        height: childrenRect.height + 15
        width: base.width - 10
        anchors.top: parent.top; anchors.left: parent.left
        anchors.topMargin: 10; anchors.leftMargin: 15
        Column {
            spacing: 7
            width: parent.width
            Layout.leftMargin: 50
            Text { text: catalog.i18nc("@label", "Preparing..."); color: "white"; font.bold: true; width: 125; font.pointSize: 14 }
            ProgressBar {
                id: progressBar
                value: base.progress
                padding: 2

                background: Rectangle {
                    implicitWidth: parent.width
                    implicitHeight: 24
                    color: UM.Theme.getColor("sidebar_item_glow")
                    radius: 3
                }

                contentItem: Item {
                    implicitWidth: base.width - 44
                    implicitHeight: 16

                    Rectangle {
                        width: progressBar.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: "#17a81a" // green
                        Text {
                            color: "white"
                            font: UM.Theme.getFont("small")
                            text: parseInt(progressBar.value * 100, 10) + "%"
                            anchors.horizontalCenter: parent.horizontalCenter
                            leftPadding: 15
                            topPadding: 2
                        }
                    }
                }
            }
            Button {
                id: cancelProgress
                width: 80; height: 30
                background: Rectangle {
                    border.color: "black"
                    border.width: 1
                    color: "#d9534f"
                    radius: 2
                }
                contentItem: Text {
                    leftPadding: 5
                    color: "white"
                    text: ""
                    font { family: fontAwesomeSolid.name; pointSize: 12 }
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
                Label {
                    color: "white"
                    leftPadding: 25
                    topPadding: 2
                    font: UM.Theme.getFont("default_bold")
                    anchors.top: parent.contentItem.top
                    anchors.left: parent.left
                    horizontalAlignment: Text.AlignLeft
                    text: catalog.i18nc("@label", " Cancel")
                }
                onClicked: {
                    CuraApplication.backend.stopSlicing();
                    UM.Controller.setActiveView("SolidView")
                }
            }
        }
    }

}
