// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.10
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2

import UM 1.3 as UM
import Cura 1.0 as Cura

import "Menus"

UM.MainWindow
{
    id: base
    title: "XDesktop"
    viewportRect: Qt.rect(0, 0, (base.width - sidebar.width) / base.width, 1.0)

    backgroundColor: UM.Theme.getColor("viewport_background")

    property int currentBackendState: 1 // Solidview

    Cura.MaterialBrandsModel { id: materialBrandsModel } // make this global here.

    function firstrunOpenFile() {
        base.showFirstrunTip(
            { x: toolbarBackground.width, y: openFileButton.y + 15 },
            catalog.i18nc("@firstrun", "Open File"),
            catalog.i18nc("@firstrun", "Import a 3D model"))
    }

    Connections
    {
        target: CuraApplication
        onActivityChanged: {
            if (CuraApplication.platformActivity && UM.Backend.state == 1) {
                if (UM.Preferences.getValue("general/firstrun") && UM.Preferences.getValue("general/firstrun_step") == 1) {
                    UM.Preferences.setValue("general/firstrun_step", 2)
                    base.showFirstrunTip(
                        { x: toolbarBackground.width, y: centerModelButton.y + 14 },
                        catalog.i18nc("@firstrun", "Model Modifications"),
                        catalog.i18nc("@firstrun", "From this panel you can center, multiply, re-position and mirror your model. Or you can use the support blocker"),
                        true,
                        "../../resources/images/first-run/modifications_" + UM.Preferences.getValue("general/language") + ".png")
                }
            // 2 - loading, 3 - done
            } else if (UM.Preferences.getValue("general/firstrun")) {
                if ([2, 3].indexOf(UM.Backend.state) == -1) {
                    base.firstrunOpenFile()
                    // set to 1 no matter what since there is no model left
                    UM.Preferences.setValue("general/firstrun_step", 1)
                } else if (UM.Backend.state == 3)  {
                    UM.Preferences.setValue("general/firstrun_step", 7)
                }
            }

            if (!CuraApplication.platformActivity && UM.Controller.activeStage.stageId == "PrepareStage")
                UM.Controller.setActiveStage("NetworkMachineList")
        }
    }

    Connections
    {
        target: UM.Backend
        onBackendStateChange: {
            // SolidView if not sliced - 1 = Ready to slice - 4 = Unable to slice
            // 5 = Slicing unavailable
            if (base.currentBackendState == UM.Backend.state)
                return

            base.currentBackendState = UM.Backend.state

            switch (base.currentBackendState) {
                case 1:
                case 4:
                    UM.Controller.setActiveView("SolidView")
                    break;
                case 2:
                    UM.Controller.setActiveView("SimulationView")
                    UM.Controller.setActiveStage("NetworkMachineList")
                    // Take snapshot while loading is a better idea
                    Cura.Actions.takeSnapshot.trigger()
                    Cura.Actions.takeModelSnapshot.trigger()
                    break;
            }
        }
    }

    ImageStreamPopup {
        id: imageStreamPopup
        width: 576
        height: 766
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    }

    onWidthChanged:
    {
        // If slidebar is collapsed then it should be invisible
        // otherwise after the main_window resize the sidebar will be fully re-drawn
        if (sidebar.collapsed){
            if (sidebar.visible == true){
                sidebar.visible = false
                sidebar.initialWidth = 0
            }
        }
        else{
            if (sidebar.visible == false){
                sidebar.visible = true
                sidebar.initialWidth = UM.Theme.getSize("sidebar").width
            }
        }
    }

    Component.onCompleted:
    {
        CuraApplication.setMinimumWindowSize(UM.Theme.getSize("window_minimum_size"))
        // Workaround silly issues with QML Action's shortcut property.
        //
        // Currently, there is no way to define shortcuts as "Application Shortcut".
        // This means that all Actions are "Window Shortcuts". The code for this
        // implements a rather naive check that just checks if any of the action's parents
        // are a window. Since the "Actions" object is a singleton it has no parent by
        // default. If we set its parent to something contained in this window, the
        // shortcut will activate properly because one of its parents is a window.
        //
        // This has been fixed for QtQuick Controls 2 since the Shortcut item has a context property.
        Cura.Actions.parent = backgroundItem
        CuraApplication.purgeWindows()
    }

    function showFirstrunTip(position, title, text, nextAvailable, imgPath) {
        if (sidebar.collapsed) {
            firstrunTip.hide()
            return
        }
        firstrunTip.title = title;
        firstrunTip.text = text;
        firstrunTip.nextAvailable = typeof nextAvailable != "undefined" ? nextAvailable : false
        firstrunTip.imgPath = (typeof imgPath === "undefined" || imgPath == "" ? "" : imgPath)
        firstrunTip.z = UM.Preferences.getValue("general/firstrun_step") > 2 ? 1 : 0
        firstrunTip.show(position)
    }

    Item
    {
        id: backgroundItem;
        anchors.fill: parent;
        UM.I18nCatalog{id: catalog; name:"cura"}

        signal hasMesh(string name) //this signal sends the filebase name so it can be used for the JobSpecs.qml
        function getMeshName(path){
            //takes the path the complete path of the meshname and returns only the filebase
            var fileName = path.slice(path.lastIndexOf("/") + 1)
            var fileBase = fileName.slice(0, fileName.indexOf("."))
            return fileBase
        }

        //DeleteSelection on the keypress backspace event
        Keys.onPressed: {
            if (event.key == Qt.Key_Backspace)
            {
                Cura.Actions.deleteSelection.trigger()
            }
        }

        Tooltip
        {
            id: firstrunTip
            onClose : function() {
                // user skipped first-run by clicking on close button
                UM.Preferences.setValue("general/firstrun", false)
                UM.Preferences.setValue("general/firstrun_step", 1)
            }
            onNext : function() {
                // user skipped first-run step by clicking on next button
                UM.Preferences.setValue("general/firstrun_step", UM.Preferences.getValue("general/firstrun_step") + 1)
            }
        }

        UM.ApplicationMenu
        {
            id: menu
            window: base

            Menu
            {
                id: fileMenu
                title: catalog.i18nc("@title:menu menubar:toplevel","&File");

                MenuItem
                {
                    id: openMenu
                    action: Cura.Actions.open;
                }

                RecentFilesMenu { }

                MenuSeparator { }

                MenuItem
                {
                    id: saveAsMenu
                    text: catalog.i18nc("@title:menu menubar:file", "&Export...")
                    onTriggered:
                    {
                        var localDeviceId = "local_file";
                        UM.OutputDeviceManager.requestWriteToDevice(localDeviceId, PrintInformation.jobName, { "filter_by_machine": false, "preferred_mimetypes": "application/vnd.ms-package.3dmanufacturing-3dmodel+xml"});
                    }
                }

                MenuItem
                {
                    id: exportSelectionMenu
                    text: catalog.i18nc("@title:menu menubar:file", "Export Selection...");
                    enabled: UM.Selection.hasSelection;
                    iconName: "document-save-as";
                    onTriggered: UM.OutputDeviceManager.requestWriteSelectionToDevice("local_file", PrintInformation.jobName, { "filter_by_machine": false, "preferred_mimetypes": "application/vnd.ms-package.3dmanufacturing-3dmodel+xml"});
                }

                MenuSeparator { }

                MenuItem
                {
                    id: reloadAllMenu
                    action: Cura.Actions.reloadAll;
                }

                MenuSeparator { }

                MenuItem { action: Cura.Actions.quit; }
            }

            Menu
            {
                title: catalog.i18nc("@title:menu menubar:toplevel","&Edit");

                MenuItem { action: Cura.Actions.undo; }
                MenuItem { action: Cura.Actions.redo; }
                MenuSeparator { }
                MenuItem { action: Cura.Actions.selectAll; }
                MenuItem { action: Cura.Actions.arrangeAll; }
                MenuItem { action: Cura.Actions.deleteSelection; }
                MenuItem { action: Cura.Actions.deleteAll; }
                MenuItem { action: Cura.Actions.resetAllTranslation; }
                MenuItem { action: Cura.Actions.resetAll; }
                MenuSeparator { }
                MenuItem { action: Cura.Actions.groupObjects;}
                MenuItem { action: Cura.Actions.mergeObjects;}
                MenuItem { action: Cura.Actions.unGroupObjects;}
            }

            Menu
            {
                id: settingsMenu
                title: catalog.i18nc("@title:menu menubar:toplevel", "&Settings")

                Menu
                {
                    title: catalog.i18nc("@title:menu menubar:settings","&Language")
                    id: languageMenu
                    Instantiator
                    {
                        onObjectRemoved: languageMenu.removeItem(object)
                        onObjectAdded: languageMenu.insertItem(index, object)

                        model: ListModel
                        {
                            id: languageList

                            Component.onCompleted: {
                                append({ text: "English", code: "en_US" })
                                append({ text: "Türkçe", code: "tr_TR" })
                            }
                        }
                        MenuItem
                        {
                            text: languageList.get(index).text
                            checkable: true;
                            checked: UM.Preferences.getValue("general/language") == languageList.get(index).code
                            onTriggered:
                            {
                                UM.Preferences.setValue("general/language", languageList.get(index).code)
                                languageExitConfirmationDialog.open();
                            }
                        }
                    }
                }

                Menu
                {
                    title: catalog.i18nc("@title:menu menubar:settings", "&Device")
                    NozzleMenu { title: catalog.i18nc("@title:menu menubar:settings", "&Nozzle"); visible: Cura.MachineManager.hasVariants; extruderIndex: 0 }
                    ExtruderMenu { title: catalog.i18nc("@title:menu menubar:settings", "&Extruder"); visible: machineExtruderCount.properties.value > 1 }
                }

                Menu
                {
                    title: catalog.i18nc("@title:menu menubar:settings", "&View")
                    SimulationViewMenu { title: catalog.i18nc("@title:menu menubar:settings", "&Simulation"); }
                }
            }

            Menu
            {
                id: helpMenu
                title: catalog.i18nc("@title:menu menubar:toplevel","&Help");

                MenuItem { action: Cura.Actions.checkForUpdates; }
                MenuItem { action: Cura.Actions.firstrun; }
                MenuItem { action: Cura.Actions.about; }
                //MenuItem { action: Cura.Actions.showChangelog; }
                MenuItem { action: Cura.Actions.factoryReset; }
            }
        }

        Item
        {
            id: contentItem;

            y: menu.height
            width: parent.width;
            height: parent.height - menu.height;

            Keys.forwardTo: menu

            DropArea
            {
                anchors.fill: parent;
                onDropped:
                {
                    if (drop.urls.length > 0)
                    {

                        var nonPackages = [];
                        var preferredMimetypes = Cura.MachineManager.activeMachine.preferred_output_file_formats.split(";")
                        for (var i = 0; i < drop.urls.length; i++)
                        {
                            var filename = drop.urls[i];
                            var extension = filename.split('.').pop()
                            var isCompatible = true
                            if (extension == "gcode")
                                for (var j in preferredMimetypes) {
                                    // If the extension isn't included in devices accepted mime types
                                    if (preferredMimetypes[j].indexOf(extension) < 0)
                                        isCompatible = false
                                }
                            if (isCompatible)
                                nonPackages.push(filename);
                        }
                        if (nonPackages.length > 0)
                            openDialog.handleOpenFileUrls(nonPackages);
                    }
                }
            }

            // Toolbar background
            Rectangle {
                id: toolbarBackground
                color: UM.Theme.getColor("sidebar_item_light")
                width: UM.Theme.getSize("toolbar").width
                anchors
                {
                    top: parent.top;
                    bottom: parent.bottom;
                    left: parent.left;
                }
            }

            Button
            {
                id: openFileButton;
                text: catalog.i18nc("@action:button","Open File");
                style: UM.Theme.styles.tool_button
                property string iconText : "A"
                tooltip: ""
                anchors
                {
                    top: topbar.bottom;
                    topMargin: 15
                    left: parent.left;
                    leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2)
                }
                action: Cura.Actions.open;
            }

            // Bottom Border
            Rectangle { id: openFileButtonBottomBorder; anchors { top: openFileButton.bottom; left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: UM.Theme.getSize("toolbar_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }

            Button
            {
                id: centerModelButton;
                text: catalog.i18ncp("@action:inmenu menubar:edit", "Center Selected Model", "Center Selected Models", UM.Selection.selectionCount)
                style: UM.Theme.styles.tool_button
                property string iconText : "B"
                tooltip: ""
                anchors
                {
                    top: openFileButtonBottomBorder.bottom;
                    left: parent.left;
                    leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2)
                }
                action: Cura.Actions.centerSelection;
            }

            // Bottom Border
            Rectangle { id: centerModelButtonBottomBorder; anchors { top: centerModelButton.bottom; left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: UM.Theme.getSize("toolbar_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }

            Button
            {
                id: multiplyModelButton;
                text: catalog.i18ncp("@action:inmenu menubar:edit", "Multiply Selected Model", "Multiply Selected Models", UM.Selection.selectionCount)
                property string iconText: "F"
                style: UM.Theme.styles.tool_button
                tooltip: ""
                anchors
                {
                    top: centerModelButtonBottomBorder.bottom;
                    left: parent.left;
                    leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2)
                }
                action: Cura.Actions.multiplySelection;
            }

            // Bottom Border
            Rectangle { id: multiplyModelButtonBottomBorder; anchors { top: multiplyModelButton.bottom; left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: UM.Theme.getSize("toolbar_lining").height; color: UM.Theme.getColor("sidebar_item_dark") }

            Toolbar
            {
                id: toolbar;

                property int mouseX: base.mouseX
                property int mouseY: base.mouseY
                property var marginL: toolbarBackground.width

                anchors {
                    top: multiplyModelButtonBottomBorder.bottom;
                    left: parent.left;
                }
            }

            Topbar
            {
                id: topbar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
            }

            Loader
            {
                id: main

                anchors
                {
                    top: topbar.bottom
                    bottom: parent.bottom
                    left: parent.left
                    right: sidebar.left
                }

                MouseArea
                {
                    visible: UM.Controller.activeStage.mainComponent != ""
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onWheel: wheel.accepted = true
                }

                source: UM.Controller.activeStage.mainComponent
            }

            Loader
            {
                id: view_panel

                anchors.top: sidebar.top
                anchors.topMargin: UM.Theme.getSize("default_margin").height
                anchors.left: toolbarBackground.right
                anchors.right: sidebar.left
                anchors.bottom: sidebar.bottom
                anchors.rightMargin: UM.Theme.getSize("default_margin").width

                //property var buttonTarget: Qt.point(viewModeButton.x + Math.round(viewModeButton.width / 2), viewModeButton.y + Math.round(viewModeButton.height / 2))

                height: childrenRect.height
                width: childrenRect.width

                source: UM.ActiveView.valid ? UM.ActiveView.activeViewPanel : "";
            }

            Loader
            {
                id: sidebar
                z: 0

                property bool collapsed: false;
                property var initialWidth: UM.Theme.getSize("sidebar").width;

                function callExpandOrCollapse() {
                    if (collapsed) {
                        sidebar.visible = true;
                        sidebar.initialWidth = UM.Theme.getSize("sidebar").width;
                        viewportRect = Qt.rect(0, 0, (base.width - sidebar.width) / base.width, 1.0);
                        expandSidebarAnimation.start();
                    } else {
                        viewportRect = Qt.rect(0, 0, 1, 1.0);
                        collapseSidebarAnimation.start();
                    }
                    collapsed = !collapsed;
                    UM.Preferences.setValue("cura/sidebar_collapsed", collapsed);
                }

                anchors
                {
                    top: topbar.top
                    bottom: parent.bottom
                }

                width: initialWidth
                x: base.width - sidebar.width
                source: UM.Controller.activeStage.sidebarComponent

                NumberAnimation {
                    id: collapseSidebarAnimation
                    target: sidebar
                    properties: "x"
                    to: base.width
                    duration: 100
                }

                NumberAnimation {
                    id: expandSidebarAnimation
                    target: sidebar
                    properties: "x"
                    to: base.width - sidebar.width
                    duration: 100
                }

                Component.onCompleted:
                {
                    var sidebar_collapsed = UM.Preferences.getValue("cura/sidebar_collapsed");

                    if (sidebar_collapsed)
                    {
                        sidebar.collapsed = true;
                        viewportRect = Qt.rect(0, 0, 1, 1.0)
                        collapseSidebarAnimation.start();
                    }
                }

                MouseArea
                {
                    visible: UM.Controller.activeStage.sidebarComponent != ""
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onWheel: wheel.accepted = true
                }
            }

            Connections {
                target: sidebar.item
                onShowFirstrunTip: {
                    x: base.width - sidebar.width
                    base.showFirstrunTip( { x: base.width - sidebar.width, y: position.y }, title, text, nextAvailable, imgPath)
                }
                onShowPopup: {
		    imageStreamPopup.url = url
		    imageStreamPopup.title = title
		    imageStreamPopup.open()
                }
            }

            // Expand / Collapse bar
            Image {
                id: toggleSidebarButton
                width: 24; height: 39
                source: "../images/" + (sidebar.collapsed ? "expand" : "collapse") + ".png"
                anchors {
                    verticalCenter: sidebar.verticalCenter
                    right: sidebar.left
                    rightMargin: -1
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidebar.callExpandOrCollapse()
                }
            }

            UM.MessageStack
            {
                anchors
                {
                    horizontalCenter: parent.horizontalCenter
                    horizontalCenterOffset: -(Math.round(UM.Theme.getSize("sidebar").width / 2))
                    top: parent.verticalCenter;
                    bottom: parent.bottom;
                    bottomMargin:  UM.Theme.getSize("default_margin").height
                }
            }
        }
    }

    // Expand or collapse sidebar
    Connections
    {
        target: Cura.Actions.expandSidebar
        onTriggered: sidebar.callExpandOrCollapse()
    }

    ContextMenu {
        id: contextMenu
    }

    onPreClosing:
    {
        close.accepted = CuraApplication.getIsAllChecksPassed();
        if (!close.accepted)
        {
            CuraApplication.checkAndExitApplication();

            if (UM.Preferences.getValue("general/firstrun"))
                UM.Preferences.setValue("general/firstrun_step", 1)
        }
    }

    MessageDialog
    {
        id: languageExitConfirmationDialog
        title: catalog.i18nc("@title:window", "Closing XDesktop")
        text: catalog.i18nc("@label", "You will need to re-open XDesktop for the changes to take effect. Are you sure you want to exit XDesktop?")
        icon: StandardIcon.Question
        modality: Qt.ApplicationModal
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: CuraApplication.checkAndExitApplication()
        onNo: CuraApplication.callConfirmExitDialogCallback(false)
        onRejected: CuraApplication.callConfirmExitDialogCallback(false)
        onVisibilityChanged:
        {
            if (!visible)
            {
                // reset the text to default because other modules may change the message text.
                text = catalog.i18nc("@label", "You will need to re-open XDesktop for the changes to take effect. Are you sure you want to exit XDesktop?")
            }
        }
    }

    MessageDialog
    {
        id: exitConfirmationDialog
        title: catalog.i18nc("@title:window", "Closing XDesktop")
        text: catalog.i18nc("@label", "Are you sure you want to exit XDesktop?")
        icon: StandardIcon.Question
        modality: Qt.ApplicationModal
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: CuraApplication.callConfirmExitDialogCallback(true)
        onNo: CuraApplication.callConfirmExitDialogCallback(false)
        onRejected: CuraApplication.callConfirmExitDialogCallback(false)
        onVisibilityChanged:
        {
            if (!visible)
            {
                // reset the text to default because other modules may change the message text.
                text = catalog.i18nc("@label", "Are you sure you want to exit XDesktop?");
            }
        }
    }

    Connections
    {
        target: CuraApplication
        onShowConfirmExitDialog:
        {
            exitConfirmationDialog.text = message;
            exitConfirmationDialog.open();
        }
    }

    Connections
    {
        target: Cura.Actions.quit
        onTriggered: CuraApplication.checkAndExitApplication();
    }

    Connections
    {
        target: Cura.Actions.toggleFullScreen
        onTriggered: base.toggleFullscreen();
    }

    FileDialog
    {
        id: openDialog;

        //: File open dialog title
        title: catalog.i18nc("@title:window","Open file(s)")
        modality: UM.Application.platform == "linux" ? Qt.NonModal : Qt.WindowModal;
        selectMultiple: true
        nameFilters: UM.MeshFileHandler.supportedReadFileTypes({ "preferred_mimetypes": Cura.MachineManager.activeMachine.preferred_output_file_formats });
        folder: CuraApplication.getDefaultPath("dialog_load_path")
        onAccepted:
        {
            // Because several implementations of the file dialog only update the folder
            // when it is explicitly set.
            var f = folder;
            folder = f;

            CuraApplication.setDefaultPath("dialog_load_path", folder);

            handleOpenFileUrls(fileUrls);
        }

        // Yeah... I know... it is a mess to put all those things here.
        // There are lots of user interactions in this part of the logic, such as showing a warning dialog here and there,
        // etc. This means it will come back and forth from time to time between QML and Python. So, separating the logic
        // and view here may require more effort but make things more difficult to understand.
        function handleOpenFileUrls(fileUrlList)
        {
            var hasGcode = false;
            var nonGcodeFileList = [];
            for (var i in fileUrlList)
            {
                var endsWithGcode = /(\.zaxe$|\.gcode$)/;
                if (endsWithGcode.test(fileUrlList[i]))
                {
                    continue;
                }
                nonGcodeFileList.push(fileUrlList[i]);
            }
            hasGcode = nonGcodeFileList.length < fileUrlList.length;

            // show a warning if selected multiple files together with Gcode
            var selectedMultipleFiles = fileUrlList.length > 1;
            if (selectedMultipleFiles && hasGcode)
            {
                infoMultipleFilesWithGcodeDialog.selectedMultipleFiles = selectedMultipleFiles;
                infoMultipleFilesWithGcodeDialog.fileUrls = nonGcodeFileList.slice();
                infoMultipleFilesWithGcodeDialog.open();
            }
            else
            {
                handleOpenFiles(selectedMultipleFiles, fileUrlList)
            }
        }

        function handleOpenFiles(selectedMultipleFiles, fileUrlList)
        {
            openFilesDialog.loadModelFiles(fileUrlList.slice());
        }
    }

    MessageDialog {
        id: infoMultipleFilesWithGcodeDialog
        title: catalog.i18nc("@title:window", "Open File(s)")
        icon: StandardIcon.Information
        standardButtons: StandardButton.Ok
        text: catalog.i18nc("@text:window", "We have found one or more G-Code files within the files you have selected. You can only open one G-Code file at a time. If you want to open a G-Code file, please just select only one.")

        property var selectedMultipleFiles
        property var fileUrls

        onAccepted:
        {
            openDialog.handleOpenFiles(selectedMultipleFiles, fileUrls);
        }
    }

    Connections
    {
        target: Cura.Actions.open
        onTriggered: openDialog.open()
    }

    OpenFilesDialog
    {
        id: openFilesDialog
    }

    MessageDialog
    {
        id: messageDialog
        modality: Qt.ApplicationModal
        onAccepted: CuraApplication.messageBoxClosed(clickedButton)
        onApply: CuraApplication.messageBoxClosed(clickedButton)
        onDiscard: CuraApplication.messageBoxClosed(clickedButton)
        onHelp: CuraApplication.messageBoxClosed(clickedButton)
        onNo: CuraApplication.messageBoxClosed(clickedButton)
        onRejected: CuraApplication.messageBoxClosed(clickedButton)
        onReset: CuraApplication.messageBoxClosed(clickedButton)
        onYes: CuraApplication.messageBoxClosed(clickedButton)
    }

    Connections
    {
        target: CuraApplication
        onShowMessageBox:
        {
            messageDialog.title = title
            messageDialog.text = text
            messageDialog.informativeText = informativeText
            messageDialog.detailedText = detailedText
            messageDialog.standardButtons = buttons
            messageDialog.icon = icon
            messageDialog.visible = true
        }
    }

    AboutDialog
    {
        id: aboutDialog
    }

    Connections
    {
        target: Cura.Actions.about
        onTriggered: aboutDialog.visible = true;
    }
    Connections {
        target: Cura.Actions.firstrun
        onTriggered: UM.Preferences.setValue("general/firstrun", true)
    }

    Connections {
        target: UM.Preferences
        onPreferenceChanged:
        {
            if (UM.Preferences.getValue("general/firstrun")) {
                switch(UM.Preferences.getValue("general/firstrun_step")) {
                    case 1:
                        base.firstrunOpenFile()
                        break
                    case 9:
                        CuraApplication.message(catalog.i18nc("@firstrun", "XDesktop first-run guide has finished"), catalog.i18nc("@firstrun", "You can now continue using XDesktop... You can re-run it from Help menu if needed."))
                        firstrunTip.hide()
                        UM.Preferences.setValue("general/firstrun", false)
                        UM.Preferences.setValue("general/firstrun_step", 1)
                        break
                }
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineExtruderCount

        containerStack: Cura.MachineManager.activeMachine
        key: "machine_extruder_count"
        watchedProperties: [ "value" ]
    }

    Timer
    {
        id: startupTimer;
        interval: 100;
        repeat: false;
        running: true;
        onTriggered:
        {
            if(!base.visible)
            {
                base.visible = true;
            }

            if(Cura.MachineManager.activeMachine == null)
            {
                // Add all the machines here
                Cura.MachineManager.addMachine("X3", "zaxe_x3")
                Cura.MachineManager.addMachine("Z3+", "zaxe_z3plus")
                Cura.MachineManager.addMachine("Z3", "zaxe_z3")
                Cura.MachineManager.addMachine("Z2", "zaxe_z2")
                Cura.MachineManager.addMachine("Z1+", "zaxe_z1plus")
                Cura.MachineManager.addMachine("Z1", "zaxe_z1")
                Cura.MachineManager.addMachine("XLite", "zaxe_xlite")
                Cura.MachineManager.addMachine("X2", "zaxe_x2")
                Cura.MachineManager.addMachine("X1+", "zaxe_x1plus")
                Cura.MachineManager.addMachine("X1", "zaxe_x1")
            // If dual extruder set the same material for both extuders
            } else if (machineExtruderCount.properties.value > 1) {
                var material = Cura.MachineManager.currentRootMaterialId[0]
                Cura.MachineManager.setMaterialById(0, material)
                Cura.MachineManager.setMaterialById(1, material)
            }

            if (UM.Preferences.getValue("general/firstrun") && UM.Preferences.getValue("general/firstrun_step") == 1) {
                base.firstrunOpenFile()
            }
        }
    }
}
