# Copyright (c) 2017 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from .src import NetworkMachineList

from UM.i18n import i18nCatalog
i18n_catalog = i18nCatalog("cura")

def getMetaData():
    return {}

def register(app):
    return {
        "stage": NetworkMachineList.NetworkMachineList()
    }
