# Copyright (c) 2016 Aleph Objects, Inc.
# Cura is released under the terms of the LGPLv3 or higher.

from . import GCodeReader

from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("cura")

def getMetaData():
    return {
        "mesh_reader": [
            {
                "extension": "gcode",
                "description": i18n_catalog.i18nc("@item:inlistbox", "GCode File"),
                "device_specific": True
            }
        ]
    }


def register(app):
    app.addNonSliceableExtension(".gcode")
    return {"mesh_reader": GCodeReader.GCodeReader()}
