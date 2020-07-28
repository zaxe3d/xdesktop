import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.2 as UM
import Cura 1.0 as Cura

Item {

    id: base
    property string modelName
    property string modelId

    Button
    {
        id: printerButton
        anchors.fill: parent
        text: ""
        iconSource: UM.Theme.getImage(base.modelId)
        checkable: true
        checked: Cura.MachineManager.activeMachineId == base.modelName
        style: UM.Theme.styles.sidebar_tool_button

        //Workaround since using ToolButton's onClicked would break the binding of the checked property, instead
        //just catch the click so we do not trigger that behaviour.
        MouseArea
        {
            anchors.fill: parent;
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                switch (mouse.button) {
                    case Qt.LeftButton:
                        if (!Cura.MachineManager.machineExists(base.modelName)) {
                            Cura.MachineManager.addMachine(base.modelName, base.modelId)
                        } else {
                            Cura.MachineManager.setActiveMachine(base.modelName)
                        }

                        if (UM.Preferences.getValue("general/firstrun"))
                            UM.Preferences.setValue("general/firstrun_step", 4)
                        break;
                    case Qt.RightButton:
                        // only show variant menu if the printer is selected
                        if (printerButton.checked)
                            nozzleMenu.popup()
                        break;
                }
            }
        }
    }

    NozzleMenu {
        id: nozzleMenu
        extruderIndex: 0
    }
}
