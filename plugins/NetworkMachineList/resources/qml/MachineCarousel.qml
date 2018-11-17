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
            onClicked:
            {
                Cura.MachineManager.setActiveMachine(base.modelName)
            }
        }
    }
}
