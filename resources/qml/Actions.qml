// Copyright (c) 2015 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

pragma Singleton

import QtQuick 2.2
import QtQuick.Controls 1.1
import UM 1.1 as UM
import Cura 1.0 as Cura

Item
{
    property alias newProject: newProjectAction;
    property alias open: openAction;
    property alias quit: quitAction;

    property alias undo: undoAction;
    property alias redo: redoAction;

    property alias expandSidebar: expandSidebarAction;
    property alias takeSnapshot: takeSnapshotAction;

    property alias deleteSelection: deleteSelectionAction;
    property alias centerSelection: centerSelectionAction;
    property alias multiplySelection: multiplySelectionAction;
    property alias layFlatSelection: layFlatSelectionAction;

    property alias clearSelection: clearSelectionAction;

    property alias deleteObject: deleteObjectAction;
    property alias centerObject: centerObjectAction;
    property alias groupObjects: groupObjectsAction;
    property alias unGroupObjects:unGroupObjectsAction;
    property alias mergeObjects: mergeObjectsAction;
    //property alias unMergeObjects: unMergeObjectsAction;

    property alias multiplyObject: multiplyObjectAction;

    property alias selectAll: selectAllAction;
    property alias deleteAll: deleteAllAction;
    property alias reloadAll: reloadAllAction;
    property alias arrangeAllBuildPlates: arrangeAllBuildPlatesAction;
    property alias arrangeAll: arrangeAllAction;
    property alias arrangeSelection: arrangeSelectionAction;
    property alias resetAllTranslation: resetAllTranslationAction;
    property alias resetAll: resetAllAction;

    property alias addMachine: addMachineAction;
    property alias updateProfile: updateProfileAction;
    property alias resetProfile: resetProfileAction;

    property alias about: aboutAction;
    property alias firstrun: firstrunAction;
    property alias checkForUpdates: checkForUpdatesAction;

    property alias toggleFullScreen: toggleFullScreenAction;

    UM.I18nCatalog{id: catalog; name:"cura"}

    Action
    {
        id:toggleFullScreenAction
        text: catalog.i18nc("@action:inmenu","Toggle Full Screen");
        iconName: "view-fullscreen";
    }

    Action
    {
        id: undoAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","&Undo");
        iconName: "edit-undo";
        shortcut: StandardKey.Undo;
        onTriggered: UM.OperationStack.undo();
        enabled: UM.OperationStack.canUndo;
    }

    Action
    {
        id: redoAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","&Redo");
        iconName: "edit-redo";
        shortcut: StandardKey.Redo;
        onTriggered: UM.OperationStack.redo();
        enabled: UM.OperationStack.canRedo;
    }

    Action
    {
        id: quitAction;
        text: catalog.i18nc("@action:inmenu menubar:file","&Quit");
        iconName: "application-exit";
        shortcut: StandardKey.Quit;
    }

    Action
    {
        id: addMachineAction;
        text: catalog.i18nc("@action:inmenu menubar:printer","&Add Printer...");
    }

    Action
    {
        id: updateProfileAction;
        enabled: !Cura.MachineManager.stacksHaveErrors && Cura.MachineManager.hasUserSettings && Cura.MachineManager.activeQualityChangesGroup != null
        text: catalog.i18nc("@action:inmenu menubar:profile","&Update profile with current settings/overrides");
        onTriggered: Cura.ContainerManager.updateQualityChanges();
    }

    Action
    {
        id: resetProfileAction;
        enabled: Cura.MachineManager.hasUserSettings
        text: catalog.i18nc("@action:inmenu menubar:profile","&Discard current changes");
        onTriggered:
        {
            forceActiveFocus();
            Cura.ContainerManager.clearUserContainers();
        }
    }

    Action
    {
        id: aboutAction;
        text: catalog.i18nc("@action:inmenu menubar:help","About...");
        iconName: "help-about";
    }

    Action
    {
        id: firstrunAction;
        text: catalog.i18nc("@action:inmenu menubar:help", "First-run Guide");
    }

    Action
    {
        id: checkForUpdatesAction;
        text: catalog.i18nc("@action:inmenu menubar:help", "Check for Updates");
        onTriggered: CuraActions.checkForUpdates();
    }

    Action
    {
        id: deleteSelectionAction;
        text: catalog.i18ncp("@action:inmenu menubar:edit", "Delete Selected Model", "Delete Selected Models", UM.Selection.selectionCount);
        enabled: UM.Controller.toolsEnabled && UM.Selection.hasSelection;
        iconName: "edit-delete";
        shortcut: StandardKey.Delete;
        onTriggered: CuraActions.deleteSelection();
    }

    Action
    {
        id: centerSelectionAction;
        text: catalog.i18ncp("@action:inmenu menubar:edit", "Center Selected Model", "Center Selected Models", UM.Selection.selectionCount);
        enabled: UM.Controller.toolsEnabled && UM.Selection.hasSelection;
        iconName: "align-vertical-center";
        onTriggered: CuraActions.centerSelection();
    }

    Action
    {
        id: layFlatSelectionAction;
        text: catalog.i18ncp("@action:inmenu menubar:edit", "Lay Flat Selected Model", "Lay Flat Selected Models", UM.Selection.selectionCount);
        enabled: UM.Controller.toolsEnabled && UM.Selection.hasSelection;
        iconName: "align-vertical-center";
        onTriggered: {
            UM.Controller.setActiveTool("RotateTool");
            UM.ActiveTool.triggerAction("layFlat");
        }
    }

    Action
    {
        id: clearSelectionAction;
        text: catalog.i18ncp("@action:inmenu menubar:edit", "Clear selection");
        enabled: UM.Controller.toolsEnabled && UM.Selection.hasSelection;
        iconName: "align-vertical-center";
        onTriggered: {
            UM.Selection.clearSelection()
        }
    }

    Action
    {
        id: multiplySelectionAction;
        text: catalog.i18ncp("@action:inmenu menubar:edit", "Multiply Selected Model", "Multiply Selected Models", UM.Selection.selectionCount);
        enabled: UM.Controller.toolsEnabled && UM.Selection.hasSelection;
        iconName: "edit-duplicate";
        shortcut: "Ctrl+M"
    }

    Action
    {
        id: deleteObjectAction;
        text: catalog.i18nc("@action:inmenu","Delete Model");
        enabled: UM.Controller.toolsEnabled;
        iconName: "edit-delete";
    }

    Action
    {
        id: centerObjectAction;
        text: catalog.i18nc("@action:inmenu","Ce&nter Model on Platform");
    }

    Action
    {
        id: groupObjectsAction
        text: catalog.i18nc("@action:inmenu menubar:edit","&Group Models");
        enabled: UM.Scene.numObjectsSelected > 1 ? true: false
        iconName: "object-group"
        shortcut: "Ctrl+G";
        onTriggered: CuraApplication.groupSelected();
    }

    Action
    {
        id: reloadQmlAction
        onTriggered:
        {
            CuraApplication.reloadQML()
        }
        shortcut: "Shift+F5"
    }

    Action
    {
        id: unGroupObjectsAction
        text: catalog.i18nc("@action:inmenu menubar:edit","Ungroup Models");
        enabled: UM.Scene.isGroupSelected
        iconName: "object-ungroup"
        shortcut: "Ctrl+Shift+G";
        onTriggered: CuraApplication.ungroupSelected();
    }

    Action
    {
        id: mergeObjectsAction
        text: catalog.i18nc("@action:inmenu menubar:edit","&Merge Models");
        enabled: UM.Scene.numObjectsSelected > 1 ? true: false
        iconName: "merge";
        shortcut: "Ctrl+Alt+G";
        onTriggered: CuraApplication.mergeSelected();
    }

    Action
    {
        id: multiplyObjectAction;
        text: catalog.i18nc("@action:inmenu","&Multiply Model...");
        iconName: "edit-duplicate"
    }

    Action
    {
        id: selectAllAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","Select All Models");
        enabled: UM.Controller.toolsEnabled;
        iconName: "edit-select-all";
        shortcut: "Ctrl+A";
        onTriggered: CuraApplication.selectAll();
    }

    Action
    {
        id: deleteAllAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","Clear Build Plate");
        enabled: UM.Controller.toolsEnabled;
        iconName: "edit-delete";
        shortcut: "Ctrl+D";
        onTriggered: CuraApplication.deleteAll();
    }

    Action
    {
        id: reloadAllAction;
        text: catalog.i18nc("@action:inmenu menubar:file","Reload All Models");
        iconName: "document-revert";
        shortcut: "F5"
        onTriggered: CuraApplication.reloadAll();
    }

    Action
    {
        id: arrangeAllBuildPlatesAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","Arrange All Models To All Build Plates");
        onTriggered: Printer.arrangeObjectsToAllBuildPlates();
    }

    Action
    {
        id: arrangeAllAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","Arrange All Models");
        onTriggered: Printer.arrangeAll();
        shortcut: "Ctrl+R";
    }

    Action
    {
        id: arrangeSelectionAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","Arrange Selection");
        onTriggered: Printer.arrangeSelection();
    }

    Action
    {
        id: resetAllTranslationAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","Reset All Model Positions");
        onTriggered: CuraApplication.resetAllTranslation();
    }

    Action
    {
        id: resetAllAction;
        text: catalog.i18nc("@action:inmenu menubar:edit","Reset All Model Transformations");
        onTriggered: CuraApplication.resetAll();
    }

    Action
    {
        id: openAction;
        text: catalog.i18nc("@action:inmenu menubar:file","&Open File(s)...");
        iconName: "document-open";
        shortcut: StandardKey.Open;
    }

    Action
    {
        id: newProjectAction
        text: catalog.i18nc("@action:inmenu menubar:file","&New Project...");
        shortcut: StandardKey.New
    }

    Action
    {
        id: showEngineLogAction;
        text: catalog.i18nc("@action:inmenu menubar:help","Show Engine &Log...");
        iconName: "view-list-text";
    }

    Action
    {
        id: showProfileFolderAction;
        text: catalog.i18nc("@action:inmenu menubar:help","Show Configuration Folder");
    }

    Action
    {
        id: expandSidebarAction;
        text: catalog.i18nc("@action:inmenu menubar:view","Expand/Collapse Sidebar");
        shortcut: "Ctrl+E";
    }

    Action
    {
        id: takeSnapshotAction;
        text: "snapshot"
        shortcut: "Ctrl+T";
        onTriggered: CuraApplication.takeSnapshot();
    }

}
