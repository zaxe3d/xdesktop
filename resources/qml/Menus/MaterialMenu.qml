// Copyright (c) 2018 Ultimaker B.V.
// Cura is released under the terms of the LGPLv3 or higher.

import QtQuick 2.7
import QtQuick.Controls 1.4

import UM 1.2 as UM
import Cura 1.0 as Cura

Menu
{
    id: menu
    title: catalog.i18nc("@label:category menu label", "Material")

    property int extruderIndex: 0

    property var materialNames : {
        "zaxe_abs": "Zaxe ABS",
        "zaxe_pla": "Zaxe PLA",
        "zaxe_tpu": "Zaxe FLEX",
        "custom": "Custom"
    }

    Cura.ZaxeMaterialsModel
    {
        id: zaxeMaterialsModel
        extruderPosition: menu.extruderIndex
    }

    Instantiator
    {
        model: zaxeMaterialsModel
        delegate: MenuItem
        {
            text: menu.materialNames[model.name]
            checkable: true
            checked: model.root_material_id == Cura.MachineManager.currentRootMaterialId[extruderIndex]
            onTriggered: Cura.MachineManager.setMaterial(extruderIndex, model.container_node)
        }
        onObjectAdded: menu.insertItem(index, object)
        onObjectRemoved: menu.removeItem(object) // TODO: This ain't gonna work, removeItem() takes an index, not object
    }
}
