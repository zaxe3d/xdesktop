// Copyright (c) 2017 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import UM 1.3 as UM
import Cura 1.0 as Cura

import "Menus"

UM.MainWindow
{
    id: base
    //: Cura application window title
    title: "XDesktop"
    viewportRect: Qt.rect(0, 0, (base.width - sidebar.width) / base.width, 1.0)
    property bool showPrintMonitor: false

    backgroundColor: UM.Theme.getColor("viewport_background")

    property int currentBackendState: 0

    Connections
    {
        target: CuraApplication
        onActivityChanged: {

            if (CuraApplication.platformActivity && UM.Backend.state == 1)
                // Take snapshot if ready to slice - 1 = Ready to slice
                Cura.Actions.takeSnapshot.trigger()

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

            if (base.currentBackendState == 1) {
                UM.Controller.setActiveView("SolidView")
            }
            if (base.currentBackendState == 2) {
                UM.Controller.setActiveView("SimulationView")
                UM.Controller.setActiveStage("NetworkMachineList")
            } else if (UM.Backend.state == 4) {
                UM.Controller.setActiveView("SolidView")
            }
        }
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
                    text: catalog.i18nc("@action:inmenu menubar:file", "Export Selection...");
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
                                CuraApplication.checkAndExitApplication();
                            }
                        }
                    }
                }
            }

            Menu
            {
                id: helpMenu
                title: catalog.i18nc("@title:menu menubar:toplevel","&Help");

                MenuItem { action: Cura.Actions.about; }
            }
        }

        UM.SettingPropertyProvider
        {
            id: machineExtruderCount

            containerStack: Cura.MachineManager.activeMachine
            key: "machine_extruder_count"
            watchedProperties: [ "value" ]
            storeIndex: 0
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
                        for (var i = 0; i < drop.urls.length; i++)
                        {
                            var filename = drop.urls[i];
                                nonPackages.push(filename);
                        }
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
                iconSource: UM.Theme.getIcon("load")
                style: UM.Theme.styles.tool_button
                property var rectangleButton : true
                tooltip: ""
                anchors
                {
                    top: topbar.bottom;
                    topMargin: 25
                    left: parent.left;
                    leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2)
                }
                action: Cura.Actions.open;
            }

            // Bottom Border
            Rectangle { id: openFileButtonBottomBorder; anchors { top: openFileButton.bottom; left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            Button
            {
                id: centerModelButton;
                text: catalog.i18ncp("@action:inmenu menubar:edit", "Center Selected Model", "Center Selected Models", UM.Selection.selectionCount)
                iconSource: UM.Theme.getIcon("center")
                style: UM.Theme.styles.tool_button
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
            Rectangle { id: centerModelButtonBottomBorder; anchors { top: centerModelButton.bottom; left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            Button
            {
                id: multiplyModelButton;
                text: catalog.i18ncp("@title:window", "Multiply Selected Model", "Multiply Selected Models", UM.Selection.selectionCount)
                iconSource: UM.Theme.getIcon("multiply")
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
            Rectangle { id: multiplyModelButtonBottomBorder; anchors { top: multiplyModelButton.bottom; left: parent.left; leftMargin: Math.round(UM.Theme.getSize("sidebar_margin").width / 2) } width: toolbarBackground.width - UM.Theme.getSize("sidebar_margin").width; height: 2; color: UM.Theme.getColor("sidebar_item_dark") }

            Toolbar
            {
                id: toolbar;

                property int mouseX: base.mouseX
                property int mouseY: base.mouseY

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

    UM.PreferencesDialog
    {
        id: preferences

        Component.onCompleted:
        {
            //; Remove & re-add the general page as we want to use our own instead of uranium standard.
            removePage(0);
            insertPage(0, catalog.i18nc("@title:tab","General"), Qt.resolvedUrl("Preferences/GeneralPage.qml"));

            removePage(1);
            insertPage(1, catalog.i18nc("@title:tab","Settings"), Qt.resolvedUrl("Preferences/SettingVisibilityPage.qml"));

            insertPage(2, catalog.i18nc("@title:tab", "Printers"), Qt.resolvedUrl("Preferences/MachinesPage.qml"));

            insertPage(3, catalog.i18nc("@title:tab", "Materials"), Qt.resolvedUrl("Preferences/Materials/MaterialsPage.qml"));

            insertPage(4, catalog.i18nc("@title:tab", "Profiles"), Qt.resolvedUrl("Preferences/ProfilesPage.qml"));

            // Remove plug-ins page because we will use the shiny new plugin browser:
            removePage(5);

            //Force refresh
            setPage(0);
        }

        onVisibleChanged:
        {
            // When the dialog closes, switch to the General page.
            // This prevents us from having a heavy page like Setting Visiblity active in the background.
            setPage(0);
        }
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
        nameFilters: UM.MeshFileHandler.supportedReadFileTypes;
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
                var endsWithGcode = /\.zaxe$/;
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

    EngineLog
    {
        id: engineLog;
    }

    // Dialog to handle first run machine actions
    UM.Wizard
    {
        id: machineActionsWizard;

        title: catalog.i18nc("@title:window", "Add Printer")
        property var machine;

        function start(id)
        {
            var actions = Cura.MachineActionManager.getFirstStartActions(id)
            resetPages() // Remove previous pages

            for (var i = 0; i < actions.length; i++)
            {
                actions[i].displayItem.reset()
                machineActionsWizard.appendPage(actions[i].displayItem, catalog.i18nc("@title", actions[i].label));
            }

            //Only start if there are actions to perform.
            if (actions.length > 0)
            {
                machineActionsWizard.currentPage = 0;
                show()
            }
        }
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

    Connections
    {
        target: CuraApplication
        onRequestAddPrinter:
        {
            addMachineDialog.visible = true
            addMachineDialog.firstRun = false
        }
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
                Cura.MachineManager.addMachine("Z1+", "zaxe_z1plus")
                Cura.MachineManager.addMachine("X1+", "zaxe_x1plus")
                Cura.MachineManager.addMachine("X1", "zaxe_x1")
            }
        }
    }
}
