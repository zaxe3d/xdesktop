import QtQuick 2.7
import QtQuick.Controls 1.4

import Cura 1.0 as Cura

Menu
{
    title: "VerifiedMaterials"
    id: menu
    property var menuModel // model to be set externally

    Instantiator
    {
        model: menuModel

        Menu
        {
            id: submenu
            title: model.name
            property var submodel: model.materials

            Instantiator
            {
                id: submaterials
                model: submodel
                delegate: MenuItem
                {
                    text: model.description
                    checkable: true
                    checked: currentRootMaterialId == model.name
                    onTriggered: setMaterial(model.name)
                }
                onObjectAdded: submenu.insertItem(index, object)
                onObjectRemoved: submenu.removeItem(object)
            }
        }

        onObjectAdded: menu.insertItem(index, object);
        onObjectRemoved: menu.removeItem(object);
    }
}
