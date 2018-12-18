# Copyright (c) 2015 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from cura.ZaxeCodeWriter import ZaxeCodeWriter
from UM.Mesh.MeshWriter import MeshWriter #For the binary mode flag.

from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")

def getMetaData():
    return {
        "mesh_writer": {
            "output": [{
                "extension": "zaxe",
                "description": catalog.i18nc("@item:inlistbox", "Zaxe File"),
                "mode": MeshWriter.OutputMode.BinaryMode,
                "mime_type": "application/zaxe"
            }]
        }
    }

def register(app):
    return { "mesh_writer": ZaxeCodeWriter() }
