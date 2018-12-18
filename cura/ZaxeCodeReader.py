# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.


from UM.Mesh.MeshReader import MeshReader #The class we're extending/implementing.
from UM.PluginRegistry import PluginRegistry
from UM.Message import Message
from UM.i18n import i18nCatalog
from UM.MimeTypeDatabase import MimeTypeDatabase, MimeType

catalog = i18nCatalog("cura")

import zipfile
import tempfile
import json
import os

TMP_FOLDER = tempfile.gettempdir()
##  zaxe file reader
#
class ZaxeCodeReader(MeshReader):

    MIN_VERSION = [1, 0, 2]

    def __init__(self) -> None:
        super().__init__()
        MimeTypeDatabase.addMimeType(
            MimeType(
                name = "application/zaxe",
                comment="Zaxe Code",
                suffixes=["zaxe"]
            )
        )
        self._supported_extensions = [".zaxe"]

    def _read(self, fileName):
        zipFile = zipfile.ZipFile(fileName, "r")

        zipFile.extract("info.json", TMP_FOLDER)

        info = json.load(open(os.path.join(TMP_FOLDER, "info.json"), "r"))
        version = [int(ver) for ver in info["version"].rsplit(".")]

        deviceModel = PluginRegistry.getInstance().getPluginObject("GCodeReader").getCurrentDeviceModel()

        # don't import older versions (hey: no snapshot)
        if version < self.MIN_VERSION:
            infoMessage = Message(catalog.i18nc(
                "@info:zaxecode",
                "This Zaxe file belongs to an older version. Please slice your original mesh file again."),
                lifetime=10,
                title = catalog.i18nc("@info:title", "Zaxe Code Details"))
            infoMessage.show()
            return None
        elif info["model"] != deviceModel.replace("+", "PLUS"):
            infoMessage = Message(catalog.i18nc(
                "@info:zaxecode",
                "This Zaxe file is sliced for Zaxe {0}. Please switch to Zaxe {0} before importing this file again.", info["model"].replace("PLUS", "+")),
                lifetime=10,
                title = catalog.i18nc("@info:title", "Zaxe Code Details"))
            infoMessage.show()
            return None

        zipFile.extract("data.zaxe_code", TMP_FOLDER)
        zipFile.extract("snapshot.png", TMP_FOLDER)


        zaxeCode = open(os.path.join(TMP_FOLDER, "data.zaxe_code"), "r").read()

        PluginRegistry.getInstance().getPluginObject("GCodeReader").preReadFromStream(zaxeCode)
        result = PluginRegistry.getInstance().getPluginObject("GCodeReader").readFromStream(zaxeCode, info)

        return result
