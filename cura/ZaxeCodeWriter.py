# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from io import StringIO, BufferedIOBase #To write the g-code to a temporary buffer, and for typing.
from typing import cast, List

import cura.CuraApplication # To get the global container stack to find the current machine.

from UM.Logger import Logger
from UM.Mesh.MeshWriter import MeshWriter #The class we're extending/implementing.
from UM.PluginRegistry import PluginRegistry
from UM.Scene.SceneNode import SceneNode #For typing.

from UM.i18n import i18nCatalog
from UM.Qt.Duration import DurationFormat
from cura.Utils import tool

import hashlib
import zipfile
import json
import tempfile
import os
catalog = i18nCatalog("cura")

TMP_FOLDER = tempfile.gettempdir()

##  print ready Zaxe code generator
#
class ZaxeCodeWriter(MeshWriter):

    ZAXE_FILE_VERSION = "2.0.0"

    def __init__(self) -> None:
        super().__init__(add_to_recent_files = False)
        self._checkSum = None
        self._application = cura.CuraApplication.CuraApplication.getInstance()

    ##  Writes the zaxe file to a stream.
    def write(self, stream: BufferedIOBase, nodes: List[SceneNode], mode = MeshWriter.OutputMode.BinaryMode) -> bool:
        return self.generate(stream, mode)

    ##  generates zaxe file and saves it to temp folder if stream is None
    #   else writes zaxe file to input stream
    def generate(self, stream: BufferedIOBase = None, mode = MeshWriter.OutputMode.BinaryMode) -> bool:
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
        #Logger.log("d", "generated zaxe code file path is: %s" % gcodeFilePath)

        # create info.json
        printInformation = self._application.getPrintInformation()
        info = {}
        if printInformation.preSliced:
            info = printInformation.preSlicedInfo
            # remake checksum with the new file
            info["checksum"] = self.getCheckSum()
        else:
            vName = self._machineManager.activeVariantName
            info = tool.merge_two_dicts({
                "name": printInformation.baseName,
                "filament_used": printInformation.materialLengths[0] * 1000, # 0 for current build plate
                "duration": printInformation.currentPrintTime.getDisplayString(DurationFormat.Format.ISO8601),
                "material": printInformation.materialNames[0],
                "model": self._machineManager.activeMachineName.replace("+", "PLUS"),
                "version": self.ZAXE_FILE_VERSION,
                "checksum": self.getCheckSum(),
                "nozzle_diameter": float(vName) if tool.isNumber(vName) else str(vName)
                }, self.getExportParams(printInformation.materialNames[0]))

        infoFilePath = os.path.join(TMP_FOLDER, "info.json")
        snapshotFilePath = os.path.join(TMP_FOLDER, "snapshot.png")
        modelFilePath = os.path.join(TMP_FOLDER, "model.stl")

        # actually write to info.json
        with open(infoFilePath, "w") as infoFp:
            json.dump(info, infoFp)

        # generate .zaxe file with contents
        zipFile = zipfile.ZipFile(stream if stream is not None else self.getZaxeFile(), 'w', zipfile.ZIP_DEFLATED)
        zipFile.write(infoFilePath, os.path.basename(infoFilePath))
        zipFile.write(gcodeFilePath, "data.zaxe_code")
        zipFile.write(snapshotFilePath, "snapshot.png")
        model = self._machineManager.activeMachineName.replace("+", "")
        if model in ["Z2", "Z3"]: # only for Z2, Z3
            zipFile.write(modelFilePath, "model.stl")
            # os.remove(modelFilePath) # don't remove stl since it doesn't get changed regularly
        zipFile.close()

        os.remove(gcodeFilePath)
        os.remove(infoFilePath)

        return True

    def getExportParams(self, material):
        extruderStack = self._application.getExtruderManager().getInstance().getExtruderStack(0)
        preferences = self._application.getPreferences()
        commonParams = {
            "layer_height": extruderStack.getProperty("layer_height", "value"),
            "adhesion_type": extruderStack.getProperty("adhesion_type", "value"),
            "infill_density": extruderStack.getProperty("infill_sparse_density", "value"),
            "support_angle": preferences.getValue("slicing/support_angle"),
        }
        if material == "custom":
            profileIdxPrefix = "custom_material_profile/" + str(preferences.getValue("custom_material_profile/selected_index")) + "_"
            return tool.merge_two_dicts({
                "extruder_temperature": preferences.getValue(profileIdxPrefix + "material_print_temperature"),
                "bed_temperature": preferences.getValue(profileIdxPrefix + "material_bed_temperature"),
                "chamber_temperature": preferences.getValue(profileIdxPrefix + "material_chamber_temperature"),
            }, commonParams)
        else:
            return tool.merge_two_dicts({
                "extruder_temperature": extruderStack.getProperty("material_print_temperature_layer_0", "value"),
                "bed_temperature": extruderStack.getProperty("material_bed_temperature", "value"),
                "standby_temperature": extruderStack.getProperty("material_standby_temperature", "value")
            }, commonParams)

    def getCheckSum(self):
        #if self._checkSum is None:
        self._checkSum = self.md5()
        return self._checkSum

    def md5(self):
        hash_md5 = hashlib.md5()
        with open(self.getGCodeFile(), "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def getFileBaseName(self):
        #return tool.translateChars(self._application.getPrintInformation().baseName)
        return self._application.getPrintInformation().baseName

    def getZaxeFile(self):
        return os.path.join(TMP_FOLDER, self.getFileBaseName() + ".zaxe")

    def getGCodeFile(self):
        return os.path.join(TMP_FOLDER, self.getFileBaseName() + ".zaxe_code")

