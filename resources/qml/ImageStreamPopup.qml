import QtQuick 2.10
import QtQuick.Controls 2.2

Popup {
    /* Basic popup for showing a live image without flickering */
    id: popup
    property string url: "" // url of the image
    property string title: "" // title of the image (optional)
    property int counter: 0 // to show the same image like stream
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    modal: true
    focus: true

    function reload() {
        imageContainer.setSource(popup.url + "?d=" +  popup.counter)
        counter = ((counter + 1) % 7)
    }

    onOpened: { // start here
        imageContainer.visible = false
        popup.reload() // initial set
    }

    onClosed: {
        // reset
        image1.source = ""
        image2.source = ""
    }

    Timer {
        id: streamTimer
        interval: 3000
        repeat: true
        onTriggered: popup.reload()
        running: popup.opened
    }

    Label {
        id: lblStatus
        font: UM.Theme.getFont("extra_large_bold")
        color: UM.Theme.getColor("text_sidebar")
        text: catalog.i18nc("@info:status","Connecting") + "..."
        anchors.centerIn: parent
    }

    Item {
        id: imageContainer
        anchors.fill: parent
        property int imageShown: 1 // image number that is shown
        property string initialSource: popup.url
        visible: false

        Image {
            id: image1
            anchors.fill: parent
            visible: imageShown === 1
            source: initialSource
        }

        Image {
            id: image2
            anchors.fill: parent
            visible: imageShown === 2
            source: ""
        }

        function setSource(source){
            var imageNew = imageShown === 1 ? image2 : image1;
            var imageOld = imageShown === 2 ? image2 : image1;

            imageNew.source = source;

            function finishImage(){
                if(imageNew.status === Component.Ready) {
                    imageNew.statusChanged.disconnect(finishImage);
                    imageShown = imageShown === 1 ? 2 : 1;
                    imageContainer.visible = true
                }
            }

            if (imageNew.status === Component.Loading){
                imageNew.statusChanged.connect(finishImage);
            }
            else {
                finishImage();
            }
        }
    }

    Label {
        id: lblTitle
        font: UM.Theme.getFont("large")
        color: UM.Theme.getColor("text_sidebar")
        text: popup.title
        anchors {
            bottomMargin: 5
            leftMargin: 5
            left: parent.left
            bottom: parent.bottom
        }
    }
}
