# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from io import BytesIO
from typing import cast
import tempfile
import os

from UM.Application import Application
from UM.PluginRegistry import PluginRegistry
from UM.Mesh.MeshWriter import MeshWriter #The class we're extending/implementing.
from UM.Scene.Iterator.BreadthFirstIterator import BreadthFirstIterator
from UM.Logger import Logger

class ModelSnapshot:

    # Exports contents of build plate as binary STL
    @staticmethod
    def snapshot():
        model_io = BytesIO() #We have to convert the stl into bytes.
        model_writer = cast(MeshWriter, PluginRegistry.getInstance().getPluginObject("STLWriter"))
        nodes = BreadthFirstIterator(Application.getInstance().getController().getScene().getRoot())
        if not model_writer.write(model_io, nodes, model_writer.OutputMode.BinaryMode): #Writing the stl failed.
            Logger.log("w", "Model exporting failed.")
            return False
        open(os.path.join(tempfile.gettempdir(), "model.stl"), 'wb').write(model_io.getvalue())
        Logger.log("d", "Model exporting succeeded.")
