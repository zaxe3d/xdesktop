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
                text: "<p>Zaxe objeyi 0’dan yükselerek yani katman katman inşaa eder.<br>Bu katmanlar arasındaki her bir boşluğa <i><b>katman kalınlığı</b></i> denir.</p>
                       <p><b>Mikron</b>: Milimetrenin 1000'de 1'ine mikron denir. µm sembolü ile ifade edilir. Örneğin: 100µm, 0.1mm'ye tekabül eder.</p>"
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
                text: "<p><i>Obje üzerindeki katmanların ön izlemesi</i></p>
                       <p>Yukarıdaki fotoğrafta 200 mikronluk (0.2mm) bir baskıyı çok yakından görüyoruz. Görülen her çizgi bir katmanı temsil etmektedir. Bu katmanların inceliği veya kalınlığını XDesktop üzerinden ayarlayabiliyoruz.</p>
                       <p><b><i>Katman kalınlığını azaltmak veya arttırmak baskı kalitesini her zaman olumlu veya olumsuz olarak etkilemez.</i></b></p>"
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
                text: "<p>Zaxe katmanlama yaparak yani objeyi 0’dan yükselterek çalışır.<br> Obje yükselerek oluştuğu için her bir katmanın altında bir önceki katmanın olması gerekiyor.<br>Eğer ki bir katman cihazın tablasından değil de havadan başlıyorsa bunun altına <b>support</b> yani <b>destek</b> dediğimiz, daha sonra kolayca koparılan malzemeden atılır.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Destek derece ayarları"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Zaxe belli eğimlere kadar kendisi support malzemesi gerektirmeden basabilir. Siz de ne kadar eğime kadar support malzemesi gerektiğini ayarlayabilirsiniz.<br>Derece ayarlarını Destek kısmındaki çubuğu sağa sola oynatarak ayarlayabilirsiniz:<br></p>
                       <p>Dereceyi ne kadar arttırırsanız o kadar alçak eğimlere destek malzemesi kullanırsınız. Bazı örnekler:</p>"
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
                text: "<b>Not:</b> <i>Support derecesi ne kadar arttırılırsa, baskıya hazırlama (slice) süresi o kadar artar.</i>"

            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Sökme aşaması"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Sökmeye başlamadan önce mutlaka objenin soğuması beklenmelidir. Obje soğumadan yapılan sökme işlemleri ya başarısızlıkla ya da objenin zarar görmesi ile sonuçlanır.</p>
                       <p>Obje soğuduktan sonra elinizle veya gerektiğinde Zaxe Toolbox ile gelen spatula ve yan keski ile destekleri yavaş yavaş sökebilirsiniz.</p>
                       <p>PLA materyalinde esneme katsayısı daha az olduğu için destek sökümü ABS materyaline göre daha zor olabilir.</p>"
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
                text: "<p>Objenin üstüne inşaa edilmesi için altına atılan, sökülebilir ekstra tabandır.</p>
                       <p>Aşağıdaki resimde objenin altındaki kırmızı kısımdır.</p>"
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
                text: "<p>Daha çok ABS materyalinde baskı esnasında geniş yüzeyli objelerde, objenin köşelerinde, hafif esnemeler görülebilir. Bu tarz esnemelerin önüne geçilmesi için raft kullanılmalıdır.</p>"
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
                text: "<i><b>Köşelerden esneme yapmış baskı örneği</b></i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 20
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Yapışmama"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Küçük parçaların tablaya yapışmama / devrilme sorunlarında raft açık tutulmalıdır.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 23
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Sökme aşaması"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Baskı tamamlandıktan sonra **mutlaka objenin soğuması beklenmelidir**. Çıktı soğumadan yapılan sökme işlemlerinde raft kolayca çıkmayabilir veya objeye zarar vererek çıkabilir.</p>
                       <p>Obje soğuduktan sonra elinizle veya spatulanın yardımıyla raftı basitçe objeden ayırabilirsiniz.</p>"
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
                text: "<p>Zaxe ile ürünlerinizi basarken içlerini dolu olarak veya boş olarak basabilirsiniz. Dolu objelerin doluluk oranına fill density denir. Ürünleriniz içini boş olarak yani bir kumbara / vazo gibi basmak istiyorsanız iç doluluk değerini 0% olarak girebilirsiniz. İç doluluk oranı arttıkça obje daha sağlam olacaktır ancak baskı süresi daha da uzayacaktır.</p>
                      <p>Bazı örnekler:</p>"
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
                text: "<p>Baskıyı çevreleyen/sarmalayan kısımların kalınlığını yani et kalınlığı ayarlarını Zaxe Desktop üzerinde 3 şekilde yapabiliyoruz.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 23
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Duvar sayısı"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>X-Y Ekseninde baskıyı çevreleyen sarmallara duvar (perimeter) diyoruz. Bunların sayısını Zaxe Desktop üzerinden ayarlayabiliyorsunuz. Baskı süresini kısaltmak adına bu ayarı düşürmeyi göz önünde bulundurabilirsiniz.</p>
                       <p>Çeşitli duvar kalınlığı örnekleri:</p>"
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
                text: "<i>Duvar sayısı: 3</i>"
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
                text: "<i>Duvar sayısı: 1</i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Daha şeffaf baskılar için duvar sayısını azaltabilirsiniz ama sağlamlıktan ödün verirsiniz. İç doluluğunu arttırarak sağlamlığı geri kazandırabilirsiniz.</p>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                font.pixelSize: 23
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "Üst & Alt Kapalı Katman Sayısı"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: '<p>Z Ekseninde et kalınlığı ayarları için Üst ve Alt kapalı katman sayısını değiştirebiliriz. Mesela, üstü açık bir vazo basmak istiyorsak üst kapalı katman sayısını "0" yaparak üstü açık bir obje yapabilirsiniz. Hem alt hem de üst kapalı katman sayısını "0" yaparak iki ağızı açık boru basabilirsiniz.</p>'
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
                text: "<i>Üst & Alt Kapalı Katman Sayısı: 4</i>"
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
                text: "<i>Üst Kapalı Katman Sayısı: 0</i>"
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
                text: "<i>Alt Kapalı Katman Sayısı: 4</i>"
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
                text: "<i>Üst ve Alt Kapalı Katman Sayısı: 0</i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<ul>
                        <li> Sıvı/Işık geçirmezliğini arttırmak için alt ve üst katman sayısı arttırılmalı
                        <li> Şeffaflık için alt ve üst katman sayısı azaltılmalı
                        <li> Vazo baskıları için üst katman sayısı 0'a indirilmeli (Et kalınlığı & katı olmayan modellerde)
                        <li> Alt boş bırakılmak istenen objelerin alt katman sayısı 0'a indirilmeli (Et kalınlığı & katı olmayan modellerde)
                        <li> Alt ve üst katman sayısını arttırmak baskı süresini uzatır
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
                text: "<p>Zaxe üzerindeki nozzle (uç kısım)’ın yanında bulunan fan, sıcak materyali soğutmak ve katılaştırmak için vardır. Ancak ABS materyalinde bu soğutma işlemi çatlamalara sebep olabilir.</p>"
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
                text: "<i>Çatlamış baskı örneği</i>"
            }

            Label {
                width: parent.width
                color: UM.Theme.getColor("text_sidebar")
                textFormat: Qt.RichText
                wrapMode: Text.WordWrap
                text: "<p>Fan en çok eğimli objelerin basımında kullanışlıdır. Eğer ki düz ve eğimsiz bir objeniz varsa fanı kapatabilirsiniz ve çatlama sorunlarının önüne geçebilirsiniz.</p>
                       <p>Özetle fan hızını azaltma gerekçeleri şunlar olabilir:</p>
                       <ul>
                         <li> Uzun süreli baskılar
                         <li> Az veya eğimsiz, düz objelerde
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
                text: "<p>XY Tolerans ayarı, tek parça hareketli baskılarda veya delik toleranslarını tutturmak için kullanışlıdır.</p>
                       <p>Objedeki tüm poligonlar XY tolerans ayarı kadar boyutlandırılır ve bu şekilde, çıktı hassasiyetini ayarlayabilirsiniz.</p>"
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
                text: "<i>XY tolerans: -0.5mm (Tüm polygonlar 0.5mm küçültüdü)</i>"
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
                text: "<i>XY tolerans: 0.5mm (Tüm polygonlar 0.5mm büyütüldü)</i>"
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
                text: "<p>Bu özellik ile objenizi geometrisi değiştirilerek minimum destek atacak hale getirilir.</p>
                       <p>Çıktınız asıl modelinizden tamamen farklı olabilir.</p>"
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
                text: "<i>Havada kalan bölümler yazıcının basabileceği şekle getirilip desteklerden kaçınılır</i>"
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
                text: "<p>Spiral mod, dış kenarların Z eksenindeki hareketlerini düzleşmesini sağlar. Bu, tüm parçada istikrarlı Z ekseni yükselişi sağlar. Bu özellik katı bir modeli tek duvarlı ve kapalı en alt katmanlı bir hale dönüştürür. Bu özellik sadece, her katmanda tek bir parça olduğu durumlarda kullanılmalıdır. Baskı öncesi simülasyonu dikkatlice inceleyiniz.</p>"
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
                text: "<i>Spiral mod kapalı</i>"
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
                text: "<i>Spiral mod açık</i>"
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
                text: "<p>Destek yapısının en alt katmanının, altındaki parçanın üst katmanıyla olan boşluk mesafesini ve destek yapısının en üst katmanının, üzerindeki parçanın alt katmanıyla olan boşluk mesafesini ayarlar. Küçük değerler, destekler söküldükten sonra parça yüzeyinin daha pürüzsüz olmasını sağlar ancak desteklerin sökülmesini zorlaştırır. Eğer bu değer arttırılırsa desteklerin sökülmesi kolaylaşır ancak parçanın desteklerle oluşturduğu temas yüzeyindeki kalitede düşme yaşanabilir. </p>"
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
                text: "<p>Nozülün üst katmanlarda bıraktığı çizgiyi engellemek ve gereken durumlarda çok ince detayları olan baskılarda nozülün gezinti hareketi sırasında bu bölgelere temas etmemesi için baskı tablasını bir miktar aşağı indirir. (Dikkat: Malzeme türü ve geometriye bağlı olarak hafif ipliklenme yapabilir.)</p>"
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
