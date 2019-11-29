# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.
from cura.ZaxeCodeReader import ZaxeCodeReader

from UM.i18n import i18nCatalog
from UM.Platform import Platform


i18n_catalog = i18nCatalog("cura")

def getMetaData():
    fileExtension = "zaxe"
    return {
        "mesh_reader": [
            {
                "extension": fileExtension,
                "description": i18n_catalog.i18nc("@item:inlistbox", "Zaxe File"),
                "device_specific": True
            }
        ]
    }


def register(app):
    app.addNonSliceableExtension(".zaxe")
    return { "mesh_reader": ZaxeCodeReader() }
