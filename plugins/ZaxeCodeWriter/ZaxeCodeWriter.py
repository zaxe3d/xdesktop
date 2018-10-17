# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from io import StringIO, BufferedIOBase #To write the g-code to a temporary buffer, and for typing.
from typing import cast, List

from UM.Logger import Logger
from UM.Mesh.MeshWriter import MeshWriter #The class we're extending/implementing.
from UM.PluginRegistry import PluginRegistry
from UM.Scene.SceneNode import SceneNode #For typing.

from UM.i18n import i18nCatalog
from UM.Qt.Duration import DurationFormat
from cura.Utils import tool
from cura.CuraApplication import CuraApplication
import hashlib
import gzip
import zipfile
import json
import tempfile
import os
catalog = i18nCatalog("cura")

TMP_FOLDER = tempfile.gettempdir()

##  print ready Zaxe code generator
#
class ZaxeCodeWriter(MeshWriter):

    ZAXE_FILE_VERSION = "1.0.1"

    def __init__(self) -> None:
        super().__init__(add_to_recent_files = False)
        self._checkSum = None
        self._application = CuraApplication.getInstance()

    def generate(self) -> bool:

        self._machineManager = self._application.getMachineManager()
        Logger.log("d", "generating zaxe code")
        # Get the g-code from the g-code writer.
        gcode_textio = StringIO() #We have to convert the g-code into bytes.
        gcode_writer = cast(MeshWriter, PluginRegistry.getInstance().getPluginObject("GCodeWriter"))
        success = gcode_writer.write(gcode_textio, None)
        if not success: #Writing the g-code failed. Then I can also not write the gzipped g-code.
            self.setInformation(gcode_writer.getInformation())
            return False

        # get gcode file path
        gcodeFilePath = self.getGCodeFile()
        # get gcode-content
        result = gcode_textio.getvalue().encode("utf-8")
        # write content to file
        open(gcodeFilePath, 'wb').write(result)
        Logger.log("d", "generated zaxe code file path is: %s" % gcodeFilePath)

        Logger.log("e", "nozzle: %s" % self._machineManager.globalVariantName)

        # create info.json
        printInformation = self._application.getPrintInformation()
        info = tool.merge_two_dicts({
            "filament_used": printInformation.materialLengths[0] * 1000, # 0 for current build plate
            "duration": printInformation.currentPrintTime.getDisplayString(DurationFormat.Format.ISO8601),
            "material": printInformation.materialNames[0], # 0 for current build plate
            "model": self._machineManager.activeMachineName,
            "version": self.ZAXE_FILE_VERSION,
            "checksum": self.getCheckSum(),
            "nozzle_diameter": "0.4" # self._machineManager.globalVariantName # FIXME hardcoded
            }, self.get_export_params())
        infoFilePath = os.path.join(TMP_FOLDER, "info.json")

        # actually write to info.json
        with open(infoFilePath, "w") as infoFp:
            json.dump(info, infoFp)

        # generate .zaxe file with contents
        zipFile = zipfile.ZipFile(self.getZaxeFile(), 'w', zipfile.ZIP_DEFLATED)
        zipFile.write(infoFilePath, os.path.basename(infoFilePath))
        zipFile.write(gcodeFilePath, "data.zaxe_code")
        zipFile.close()

        return True

    def get_export_params(self):
        #if Settings.get("material") == "custom":
        #    print_temp = CustomSettings.get("material_print_temperature_layer_0")
        #    bed_temp = CustomSettings.get("material_bed_temperature_layer_0")
        #else:
        #    print_layer_0 = self.get_non_custom_config()["material_print_temperature_layer_0"]
        #    bed_layer_0 = self.get_non_custom_config()["material_bed_temperature_layer_0"]
        #    print_temp = print_layer_0 if print_layer_0 is not None else self.get_non_custom_config()["material_print_temperature"]
        #    bed_temp = bed_layer_0 if bed_layer_0 is not None else self.get_non_custom_config()["material_bed_temperature"]
        return {
            "extruder_temperature": 250,#float(print_temp),
            "bed_temperature": 100#float(bed_temp)
        }

    def getCheckSum(self):
        if self._checkSum is None:
            self._checkSum = self.md5()
        return self._checkSum

    def md5(self):
        hash_md5 = hashlib.md5()
        with open(self.getGCodeFile(), "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def getFileBaseName(self):
        return tool.clearChars(self._application.getPrintInformation().jobName)

    def getZaxeFile(self):
        return os.path.join(TMP_FOLDER, self.getFileBaseName() + ".zaxe")

    def getGCodeFile(self):
        return os.path.join(TMP_FOLDER, self.getFileBaseName() + ".zaxe_code")
