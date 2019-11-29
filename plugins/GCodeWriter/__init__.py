# Copyright (c) 2015 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from . import GCodeWriter

from UM.i18n import i18nCatalog
catalog = i18nCatalog("cura")

def getMetaData():
    return {


        "mesh_writer": {
            "output": [{
                "extension": "gcode",
                "description": catalog.i18nc("@item:inlistbox", "G-code File"),
                "mime_type": "text/x-gcode",
                "mode": GCodeWriter.GCodeWriter.OutputMode.TextMode,
                "hide_in_file_dialog": True,
                "device_specific": True
            }]
        }
    }

def register(app):
    return { "mesh_writer": GCodeWriter.GCodeWriter() }
