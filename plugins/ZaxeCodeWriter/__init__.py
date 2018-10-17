# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from UM.i18n import i18nCatalog
from UM.Platform import Platform

from . import ZaxeCodeWriter

catalog = i18nCatalog("cura")

def getMetaData():
    file_extension = "zip"
    return {
        "mesh_writer": {
            "output": [{
                "extension": file_extension,
                "description": "generates Zaxe print ready file",
                "mime_type": "application/zip",
                "hide_in_file_dialog": True
            }]
        }
    }

def register(app):
    return { "mesh_writer": ZaxeCodeWriter.ZaxeCodeWriter() }
