// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls 2.0 as C2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3

import UM 1.2 as UM
import Cura 1.0 as Cura

Item
{
    id: base

    anchors.fill: parent

    UM.I18nCatalog { id: catalog; name: "cura" }

    ListModel
    {
        id: modesListModel
    }

    Rectangle
    {
        id: page
        color: UM.Theme.getColor("sidebar")
        anchors.fill: parent
    }

    Component.onCompleted:
    {
        modesListModel.append({
            item: layerHeight
        })
        modesListModel.append({
            item: support
        })
        modesListModel.append({
            item: raft
        })
        modesListModel.append({
            item: infill
        })
        modesListModel.append({
            item: perimeterCount
        })
        modesListModel.append({
            item: fanSpeed
        })
        modesListModel.append({
            item: xyTolerance
        })
        modesListModel.append({
            item: avoidSupports
        })
        modesListModel.append({
            item: spiralVaseMode
        })
        modesListModel.append({
            item: supportContactDistance
        })
        modesListModel.append({
            item: zHopWhenRetracted
        })

        sidebarContents.replace(modesListModel.get(UM.Preferences.getValue("cura/help_page")).item)
        sidebarContents.height = sidebarContents.childrenRect.height + 60
    }


    // Help pages start
    Item
    {
        id: layerHeight
        visible: false
        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Layer height")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Zaxe objeyi 0???dan y??kselerek yani katman katman in??aa eder.<br>Bu katmanlar aras??ndaki her bir bo??lu??a <i><b>katman kal??nl??????</b></i> denir.</p>
                       <p><b>Mikron</b>: Milimetrenin 1000'de 1'ine mikron denir. ??m sembol?? ile ifade edilir. ??rne??in: 100??m, 0.1mm'ye tekab??l eder.</p>"
            }
            Image {
                source: "../../plugins/Help/resources/images/layer_thickness.png"
                sourceSize.width: parent.width
            }
            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p><i>Obje ??zerindeki katmanlar??n ??n izlemesi</i></p>
                       <p>Yukar??daki foto??rafta 200 mikronluk (0.2mm) bir bask??y?? ??ok yak??ndan g??r??yoruz. G??r??len her ??izgi bir katman?? temsil etmektedir. Bu katmanlar??n inceli??i veya kal??nl??????n?? XDesktop ??zerinden ayarlayabiliyoruz.</p>
                       <p><b><i>Katman kal??nl??????n?? azaltmak veya artt??rmak bask?? kalitesini her zaman olumlu veya olumsuz olarak etkilemez.</i></b></p>"
            }
        }
    }

    Item
    {
        id: support
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Support")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Zaxe katmanlama yaparak yani objeyi 0???dan y??kselterek ??al??????r.<br> Obje y??kselerek olu??tu??u i??in her bir katman??n alt??nda bir ??nceki katman??n olmas?? gerekiyor.<br>E??er ki bir katman cihaz??n tablas??ndan de??il de havadan ba??l??yorsa bunun alt??na <b>support</b> yani <b>destek</b> dedi??imiz, daha sonra kolayca kopar??lan malzemeden at??l??r.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Destek derece ayarlar??"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Zaxe belli e??imlere kadar kendisi support malzemesi gerektirmeden basabilir. Siz de ne kadar e??ime kadar support malzemesi gerekti??ini ayarlayabilirsiniz.<br>Derece ayarlar??n?? Destek k??sm??ndaki ??ubu??u sa??a sola oynatarak ayarlayabilirsiniz:<br></p>
                       <p>Dereceyi ne kadar artt??r??rsan??z o kadar al??ak e??imlere destek malzemesi kullan??rs??n??z. Baz?? ??rnekler:</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/support-1.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>30 derece destek</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/support-2.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>40 derece destek</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/support-3.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>50 derece destek</i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<b>Not:</b> <i>Support derecesi ne kadar artt??r??l??rsa, bask??ya haz??rlama (slice) s??resi o kadar artar.</i>"

            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "S??kme a??amas??"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>S??kmeye ba??lamadan ??nce mutlaka objenin so??umas?? beklenmelidir. Obje so??umadan yap??lan s??kme i??lemleri ya ba??ar??s??zl??kla ya da objenin zarar g??rmesi ile sonu??lan??r.</p>
                       <p>Obje so??uduktan sonra elinizle veya gerekti??inde Zaxe Toolbox ile gelen spatula ve yan keski ile destekleri yava?? yava?? s??kebilirsiniz.</p>
                       <p>PLA materyalinde esneme katsay??s?? daha az oldu??u i??in destek s??k??m?? ABS materyaline g??re daha zor olabilir.</p>"
            }
        }
    }
    Item
    {
        id: raft
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Raft")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Objenin ??st??ne in??aa edilmesi i??in alt??na at??lan, s??k??lebilir ekstra taband??r.</p>
                       <p>A??a????daki resimde objenin alt??ndaki k??rm??z?? k??s??md??r.</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/raft.jpg"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Ne zaman gerekir?"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Esneme"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Daha ??ok ABS materyalinde bask?? esnas??nda geni?? y??zeyli objelerde, objenin k????elerinde, hafif esnemeler g??r??lebilir. Bu tarz esnemelerin ??n??ne ge??ilmesi i??in raft kullan??lmal??d??r.</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/esneme.jpg"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i><b>K????elerden esneme yapm???? bask?? ??rne??i</b></i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Yap????mama"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>K??????k par??alar??n tablaya yap????mama / devrilme sorunlar??nda raft a????k tutulmal??d??r.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 23
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "S??kme a??amas??"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Bask?? tamamland??ktan sonra **mutlaka objenin so??umas?? beklenmelidir**. ????kt?? so??umadan yap??lan s??kme i??lemlerinde raft kolayca ????kmayabilir veya objeye zarar vererek ????kabilir.</p>
                       <p>Obje so??uduktan sonra elinizle veya spatulan??n yard??m??yla raft?? basit??e objeden ay??rabilirsiniz.</p>"
            }
        }
    }
    Item
    {
        id: infill
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Fill density")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Zaxe ile ??r??nlerinizi basarken i??lerini dolu olarak veya bo?? olarak basabilirsiniz. Dolu objelerin doluluk oran??na fill density denir. ??r??nleriniz i??ini bo?? olarak yani bir kumbara / vazo gibi basmak istiyorsan??z i?? doluluk de??erini 0% olarak girebilirsiniz. ???? doluluk oran?? artt??k??a obje daha sa??lam olacakt??r ancak bask?? s??resi daha da uzayacakt??r.</p>
                      <p>Baz?? ??rnekler:</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/infill-1.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>0% Doluluk</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/infill-2.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>20% Doluluk</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/infill-3.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>80% Doluluk</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/infill_patterns.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Doldurma desenleri listedeki s??ras??yla soldan sa??a do??ru s??ras??yla</i>"
            }
        }
    }

    Item
    {
        id: perimeterCount
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Perimeter count")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Bask??y?? ??evreleyen/sarmalayan k??s??mlar??n kal??nl??????n?? yani et kal??nl?????? ayarlar??n?? Zaxe Desktop ??zerinde 3 ??ekilde yapabiliyoruz.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 23
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Duvar say??s??"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>X-Y Ekseninde bask??y?? ??evreleyen sarmallara duvar (perimeter) diyoruz. Bunlar??n say??s??n?? Zaxe Desktop ??zerinden ayarlayabiliyorsunuz. Bask?? s??resini k??saltmak ad??na bu ayar?? d??????rmeyi g??z ??n??nde bulundurabilirsiniz.</p>
                       <p>??e??itli duvar kal??nl?????? ??rnekleri:</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/perimeter-1.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Duvar say??s??: 3</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/perimeter-2.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Duvar say??s??: 1</i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Daha ??effaf bask??lar i??in duvar say??s??n?? azaltabilirsiniz ama sa??laml??ktan ??d??n verirsiniz. ???? dolulu??unu artt??rarak sa??laml?????? geri kazand??rabilirsiniz.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 23
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "??st & Alt Kapal?? Katman Say??s??"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: '<p>Z Ekseninde et kal??nl?????? ayarlar?? i??in ??st ve Alt kapal?? katman say??s??n?? de??i??tirebiliriz. Mesela, ??st?? a????k bir vazo basmak istiyorsak ??st kapal?? katman say??s??n?? "0" yaparak ??st?? a????k bir obje yapabilirsiniz. Hem alt hem de ??st kapal?? katman say??s??n?? "0" yaparak iki a????z?? a????k boru basabilirsiniz.</p>'
            }

            Image {
                source: "../../plugins/Help/resources/images/wall-thickness-1.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>??st & Alt Kapal?? Katman Say??s??: 4</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/wall-thickness-2.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>??st Kapal?? Katman Say??s??: 0</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/wall-thickness-3.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Alt Kapal?? Katman Say??s??: 4</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/wall-thickness-4.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>??st ve Alt Kapal?? Katman Say??s??: 0</i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<ul>
                        <li> S??v??/I????k ge??irmezli??ini artt??rmak i??in alt ve ??st katman say??s?? artt??r??lmal??
                        <li> ??effafl??k i??in alt ve ??st katman say??s?? azalt??lmal??
                        <li> Vazo bask??lar?? i??in ??st katman say??s?? 0'a indirilmeli (Et kal??nl?????? & kat?? olmayan modellerde)
                        <li> Alt bo?? b??rak??lmak istenen objelerin alt katman say??s?? 0'a indirilmeli (Et kal??nl?????? & kat?? olmayan modellerde)
                        <li> Alt ve ??st katman say??s??n?? artt??rmak bask?? s??resini uzat??r
                       </ul>"
            }
        }
    }

    Item
    {
        id: fanSpeed
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Fan speed")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Zaxe ??zerindeki nozzle (u?? k??s??m)?????n yan??nda bulunan fan, s??cak materyali so??utmak ve kat??la??t??rmak i??in vard??r. Ancak ABS materyalinde bu so??utma i??lemi ??atlamalara sebep olabilir.</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/catlama.jpg"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>??atlam???? bask?? ??rne??i</i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Fan en ??ok e??imli objelerin bas??m??nda kullan????l??d??r. E??er ki d??z ve e??imsiz bir objeniz varsa fan?? kapatabilirsiniz ve ??atlama sorunlar??n??n ??n??ne ge??ebilirsiniz.</p>
                       <p>??zetle fan h??z??n?? azaltma gerek??eleri ??unlar olabilir:</p>
                       <ul>
                         <li> Uzun s??reli bask??lar
                         <li> Az veya e??imsiz, d??z objelerde
                       </ul>
                       <p><b>Not:</b> PLA materyalinde fan her zaman **100%** tavsiye edilir.</p>"
            }
        }
    }
    Item
    {
        id: xyTolerance
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "XY tolerance")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>XY Tolerans ayar??, tek par??a hareketli bask??larda veya delik toleranslar??n?? tutturmak i??in kullan????l??d??r.</p>
                       <p>Objedeki t??m poligonlar XY tolerans ayar?? kadar boyutland??r??l??r ve bu ??ekilde, ????kt?? hassasiyetini ayarlayabilirsiniz.</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/xy-1.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>XY tolerans: 0</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/xy-2.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>XY tolerans: -0.5mm (T??m polygonlar 0.5mm k??????lt??d??)</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/xy-3.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>XY tolerans: 0.5mm (T??m polygonlar 0.5mm b??y??t??ld??)</i>"
            }
        }
    }
    Item
    {
        id: avoidSupports
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Avoid supports")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Bu ??zellik ile objenizi geometrisi de??i??tirilerek minimum destek atacak hale getirilir.</p>
                       <p>????kt??n??z as??l modelinizden tamamen farkl?? olabilir.</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/avoid_support_1.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Destek gerektiren bir model</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/avoid_support_2.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Havada kalan b??l??mler yaz??c??n??n basabilece??i ??ekle getirilip desteklerden ka????n??l??r</i>"
            }
        }
    }
    Item
    {
        id: spiralVaseMode
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Spiral vaze mode")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Spiral mod, d???? kenarlar??n Z eksenindeki hareketlerini d??zle??mesini sa??lar. Bu, t??m par??ada istikrarl?? Z ekseni y??kseli??i sa??lar. Bu ??zellik kat?? bir modeli tek duvarl?? ve kapal?? en alt katmanl?? bir hale d??n????t??r??r. Bu ??zellik sadece, her katmanda tek bir par??a oldu??u durumlarda kullan??lmal??d??r. Bask?? ??ncesi sim??lasyonu dikkatlice inceleyiniz.</p>"
            }

            Image {
                source: "../../plugins/Help/resources/images/spiral_off.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Spiral mod kapal??</i>"
            }

            Image {
                source: "../../plugins/Help/resources/images/spiral_on.png"
                sourceSize.width: parent.width
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<i>Spiral mod a????k</i>"
            }
        }
    }
    Item
    {
        id: supportContactDistance
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Support contact distance")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Destek yap??s??n??n en alt katman??n??n, alt??ndaki par??an??n ??st katman??yla olan bo??luk mesafesini ve destek yap??s??n??n en ??st katman??n??n, ??zerindeki par??an??n alt katman??yla olan bo??luk mesafesini ayarlar. K??????k de??erler, destekler s??k??ld??kten sonra par??a y??zeyinin daha p??r??zs??z olmas??n?? sa??lar ancak desteklerin s??k??lmesini zorla??t??r??r. E??er bu de??er artt??r??l??rsa desteklerin s??k??lmesi kolayla????r ancak par??an??n desteklerle olu??turdu??u temas y??zeyindeki kalitede d????me ya??anabilir. </p>"
            }
        }
    }
    Item
    {
        id: zHopWhenRetracted
        visible: false
        height: childrenRect.height

        Column {
            spacing: 7
            width: base.width - Math.round(UM.Theme.getSize("sidebar_item_margin").width * 2)
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 30
                leftMargin: UM.Theme.getSize("sidebar_item_margin").width
            }

            // Title row
            RowLayout {
                Button {
                    Layout.preferredHeight: 20
                    style: UM.Theme.styles.sidebar_simple_button
                    text: catalog.i18nc("@label", "<")
                    onClicked: { UM.Controller.setActiveStage("PrepareStage") }
                }
                Text {
                    text: catalog.i18nc("@label", "Z hop when retracted")
                    color: UM.Theme.getColor("text_sidebar_medium")
                    width: parent.width
                    font: UM.Theme.getFont("xx_large")
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            // Bottom Border
            Rectangle { width: parent.width; height: 2; color: UM.Theme.getColor("sidebar_item_extra_dark") }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Noz??l??n ??st katmanlarda b??rakt?????? ??izgiyi engellemek ve gereken durumlarda ??ok ince detaylar?? olan bask??larda noz??l??n gezinti hareketi s??ras??nda bu b??lgelere temas etmemesi i??in bask?? tablas??n?? bir miktar a??a???? indirir. (Dikkat: Malzeme t??r?? ve geometriye ba??l?? olarak hafif ipliklenme yapabilir.)</p>"
            }
        }
    }
    // Help pages end

    Component {
        id: emptyView

        Row {
        }
    }


    ScrollView
    {
        anchors.fill: parent
        style: UM.Theme.styles.scrollview
        flickableItem.flickableDirection: Flickable.VerticalFlick

        C2.StackView
        {
            id: sidebarContents
            anchors.top: parent.top
            anchors.left: parent.left
            initialItem: emptyView

            replaceEnter: Transition {
                PropertyAnimation {
                    property: "x"
                    from: 500
                    to: 0
                    duration: 500
                    easing.type: Easing.InOutBounce
                    easing.overshoot: 2
                }
            }

            replaceExit: Transition {
                PropertyAnimation {
                    property: "x"
                    from: 0
                    to: 500
                    duration: 500
                    easing.type: Easing.InOutBounce
                    easing.overshoot: 2
                }
            }
        }
    }
}
