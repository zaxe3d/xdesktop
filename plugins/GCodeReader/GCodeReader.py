# Copyright (c) 2017 Aleph Objects, Inc.
# Cura is released under the terms of the LGPLv3 or higher.

from UM.FileHandler.FileReader import FileReader
from UM.Mesh.MeshReader import MeshReader
from UM.i18n import i18nCatalog
from UM.Application import Application
from UM.MimeTypeDatabase import MimeTypeDatabase, MimeType
from UM.Logger import Logger
from UM.Message import Message

from cura.CuraApplication import CuraApplication

catalog = i18nCatalog("cura")
from . import MarlinFlavorParser, RepRapFlavorParser


MimeTypeDatabase.addMimeType(
    MimeType(
        name = "application/x-zaxe-gcode-file",
        comment = "GCode File",
        suffixes = ["gcode"]
    )
)
MimeTypeDatabase.addMimeType(
    MimeType(
        name = "application/x-xdesktop-zaxe_code-file",
        comment = "Zaxe Code File",
        suffixes = ["zaxe_code"]
    )
)


# Class for loading and parsing G-code files
class GCodeReader(MeshReader):
    _flavor_default = "Marlin"
    _flavor_keyword = ";FLAVOR:"
    _flavor_readers_dict = {"RepRap" : RepRapFlavorParser.RepRapFlavorParser(),
                            "Marlin" : MarlinFlavorParser.MarlinFlavorParser()}

    def __init__(self) -> None:
        super().__init__()
        self._supported_extensions = ["zaxe_code", "gcode"]
        self._flavor_reader = None

    def preReadFromStream(self, stream, *args, **kwargs):
        for line in stream.split("\n"):
            if line[:len(self._flavor_keyword)] == self._flavor_keyword:
                try:
                    self._flavor_reader = self._flavor_readers_dict[line[len(self._flavor_keyword):].rstrip()]
                    return FileReader.PreReadResult.accepted
                except:
                    # If there is no entry in the dictionary for this flavor, just skip and select the by-default flavor
                    break

        # If no flavor is found in the GCode, then we use the by-default
        self._flavor_reader = self._flavor_readers_dict[self._flavor_default]
        return FileReader.PreReadResult.accepted

    # PreRead is used to get the correct flavor. If not, Marlin is set by default
    def preRead(self, file_name, *args, **kwargs):
        with open(file_name, "r", encoding = "utf-8") as file:
            file_data = file.read()
        return self.preReadFromStream(file_data, args, kwargs)

    def getCurrentDeviceModel(self):
        return CuraApplication.getInstance().getMachineManager().activeMachineName

    def readFromStream(self, stream, info = None):
        if info is not None:
            CuraApplication.getInstance().getPrintInformation().setInfo(info)

        return self._flavor_reader.processGCodeStream(stream)

    def _read(self, file_name):
        with open(file_name, "r", encoding = "utf-8") as file:
            file_data = file.read()
        return self.readFromStream(file_data)
