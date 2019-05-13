// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtQuick.Layouts 1.1

import UM 1.0 as UM

UM.PointingRectangleExt {
    id: base;

    width: img.visible ? UM.Theme.getSize("tooltip_ext").width : UM.Theme.getSize("tooltip").width;
    height: lblTitle.height + lblText.height + img.height +
            (btnNext.visible ? btnNext.height : 0) +
            UM.Theme.getSize("tooltip_margins").height * (img.visible ? 4 : 3)

    color: UM.Theme.getColor("sidebar_item_light")

    borderWidth: 1
    borderColor: UM.Theme.getColor("text_blue")

    arrowSize: UM.Theme.getSize("default_arrow").width

    opacity: 0;
    Behavior on opacity { NumberAnimation { duration: 100 } }

    property alias title: lblTitle.text
    property alias text: lblText.text
    property alias imgPath: img.source
    property alias nextAvailable: btnNext.visible

    signal close()
    onClose:
    {
        hide()
    }
    signal next()
    onNext:
    {
        hide()
    }

    function show(position) {
        var targetX = 0
        y = position.y
        if(position.x < 455) { // on the left
            position.x += UM.Theme.getSize("default_arrow").width
            x = position.x
        } else { // on the right
            position.x -= UM.Theme.getSize("default_arrow").width
            targetX = position.x  + base.width
            x = position.x - base.width;
        }
        base.opacity = 1;
        base.enabled = true
        if (Qt.platform.os == "windows") // on Windows, doesn't show where it is suppose to show in terms of Y
            position.y += 20
        target = Qt.point(targetX, position.y + Math.round(UM.Theme.getSize("tooltip_arrow_margins").height / 2))
    }

    function hide() {
        base.opacity = 0
        base.enabled = false
    }

    Label {
        id: lblTitle;
        anchors {
            top: parent.top;
            topMargin: UM.Theme.getSize("tooltip_margins").height
            left: parent.left
            leftMargin: UM.Theme.getSize("tooltip_margins").width
            right: parent.right
            rightMargin: UM.Theme.getSize("tooltip_margins").width
        }
        wrapMode: Text.Wrap
        textFormat: Text.RichText
        font: UM.Theme.getFont("default_bold")
        color: UM.Theme.getColor("tooltip_text_ext")
    }

    Label {
        id: lblText;
        anchors {
            top: lblTitle.bottom
            topMargin: UM.Theme.getSize("tooltip_margins").height
            left: parent.left
            leftMargin: UM.Theme.getSize("tooltip_margins").width
            right: parent.right
            rightMargin: UM.Theme.getSize("tooltip_margins").width
        }
        wrapMode: Text.Wrap
        textFormat: Text.RichText
        font: UM.Theme.getFont("default")
        color: UM.Theme.getColor("tooltip_text_ext")
    }

    Image {
        id: img
        visible: source != ""
        anchors {
            top: lblText.bottom
            topMargin: UM.Theme.getSize("tooltip_margins").height
            left: parent.left
            leftMargin: UM.Theme.getSize("tooltip_margins").width
            right: parent.right
            rightMargin: UM.Theme.getSize("tooltip_margins").width
            bottomMargin: UM.Theme.getSize("tooltip_margins").height
        }
    }

    Button {
        id: btnClose
        width: 27; height: width
        style: UM.Theme.styles.sidebar_simple_button
        text: "a"
        property string font: UM.Theme.getFont("zaxe_icon_set_medium")
        property int topMargin: 2
        anchors {
            top: parent.top
            right: parent.right
        }
        onClicked: {
            base.close()
        }
    }

    Button {
        id: btnNext
        visible: base.nextAvailable
        style: UM.Theme.styles.sidebar_simple_button
        text: "Q"
        property string font: UM.Theme.getFont("zaxe_icon_set")
        height: 35
        property int topMargin: 10
        anchors {
            top: img.visible ? img.bottom : lblText.bottom
            left: parent.left
            leftMargin: Math.round(UM.Theme.getSize("tooltip_margins").width / 2)
        }
        onClicked: {
            base.next()
        }
    }
}
