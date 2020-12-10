import QtQuick 2.7

// Disable mouse wheel for combobox
MouseArea {
    anchors.fill: parent
    onWheel: {
        // do nothing
    }
    onPressed: {
        // propogate to ComboBox
        mouse.accepted = false;
    }
    onReleased: {
        // propogate to ComboBox
        mouse.accepted = false;
    }
}
