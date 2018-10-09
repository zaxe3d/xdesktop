// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import UM 1.1 as UM
import Cura 1.0 as Cura

Item {
    id: base;
    UM.I18nCatalog { id: catalog; name:"cura"}

    property real progress: UM.Backend.progress
    property int backendState: UM.Backend.state
    property bool activity: CuraApplication.platformActivity

    property variant printDuration: PrintInformation.currentPrintTime
    property variant printMaterialLengths: PrintInformation.materialLengths
    property variant printMaterialWeights: PrintInformation.materialWeights
    property variant printMaterialCosts: PrintInformation.materialCosts
    property variant printMaterialNames: PrintInformation.materialNames

    property string fileBaseName
    width: parent.width - 10
    height: base.backendState != "undefined" && (base.backendState == 3 || base.backendState == 5) ?childrenRect.height + 10 : 60


    Item {
        // 3 = done, 5 = disabled
        visible: base.backendState != "undefined" && (base.backendState != 3 && base.backendState != 5)
        height: childrenRect.height
        width: base.width
        anchors.top: parent.top; anchors.left: parent.left
        Button {
            id: btnPrintNow
            width: base.width - 10; height: 50
            background: Rectangle {
                border.color: "black"
                border.width: 1
                color: "#191717"
                radius: 2
            }
            contentItem: Text {
                color: "white"
                width: parent.width
                text: {
                    if (!activity) {
                        return "Click to load a 3D model"
                    }
                    else {
                        return "SLICE \n Prepare Model for print"
                    }
                }
                font { pointSize: 15 }
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
    Item {
        // 3 = done, 5 = disabled
        // Show print details when slicing is done.
        visible: base.backendState != "undefined" && (base.backendState == 3 || base.backendState == 5)
        height: childrenRect.height
        width: base.width - 10
        anchors.top: parent.top; anchors.left: parent.left
        anchors.topMargin: 10; anchors.leftMargin: 15
        Rectangle {
            width: parent.width
            height: childrenRect.height + lblPrintDetails.height
            color: "#212121"

            Column {
                spacing: 7
                width: parent.width
                Layout.leftMargin: 50
                Text { id: lblPrintDetails; text: "Print details"; color: "white"; font.bold: true; width: 125; font.pointSize: 14 }
                Grid {
                    id: extraInfoGrid
                    property bool stateVisible: false
                    columns: 2
                    spacing: 4

                    Text { text: "Consumption"; color: "white"; font.bold: true; width: 135 }
                    Text { text: {
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
                        return  lengths.join(" + ") + "m / ~ " + weights.join(" + ") + "g";
                        }
                        color: "white"
                    }
                    Text { text: "Estimated time"; color: "white"; font.bold: true; width: 135 }
                    Text { text: (!base.printDuration || !base.printDuration.valid) ? catalog.i18nc("@label Hours and minutes", "00h 00min") : base.printDuration.getDisplayString(UM.DurationFormat.Short); color: "white" }
                    Text { text: "Material"; color: "white"; font.bold: true; width: 135 }
                    Text { text: "Zaxe ABS"; color: "white" }
                    Button {
                        id: saveToDisk
                        width: lblSave.width + 10; height: 30
                        background: Rectangle {
                            border.color: "black"
                            border.width: 1
                            color: "#17a81a"
                            radius: 2
                        }
                        contentItem: Text {
                            leftPadding: 5
                            color: "white"
                            text: ""
                            font { family: fontAwesomeSolid.name; pointSize: 12 }
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                        Label {
                            id: lblSave
                            color: "white"
                            leftPadding: 25
                            topPadding: 2
                            font { pointSize: 12; bold: true}
                            anchors.top: parent.contentItem.top
                            anchors.left: parent.left
                            horizontalAlignment: Text.AlignLeft
                            text: " Save to flash disk"
                        }
                        onClicked: {
                            UM.OutputDeviceManager.requestWriteToDevice(UM.OutputDeviceManager.activeDevice, PrintInformation.jobName,
                                { "filter_by_machine": true, "preferred_mimetypes": Cura.MachineManager.activeMachine.preferred_output_file_formats });
                        }
                    }
                    Button {
                        id: cancel
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
                            font { pointSize: 12; bold: true}
                            anchors.top: parent.contentItem.top
                            anchors.left: parent.left
                            horizontalAlignment: Text.AlignLeft
                            text: " Cancel"
                        }
                        onClicked: {
                            UM.Controller.setActiveStage("PrepareStage")
                        }
                    }
                }
            }
        }
    }

}
