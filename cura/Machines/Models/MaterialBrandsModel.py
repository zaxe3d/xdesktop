# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import Qt, pyqtSignal, pyqtProperty, QVariant
from UM.Qt.ListModel import ListModel
from UM.FlameProfiler import pyqtSlot
from UM.Logger import Logger
from cura.Machines.Models.BaseMaterialsModel import BaseMaterialsModel
from UM.i18n import i18nCatalog

class MaterialBrandsModel(BaseMaterialsModel):

    materialsChanged = pyqtSignal()

    def __init__(self, parent = None):
        super().__init__(parent)

        self.addRoleName(Qt.UserRole + 1, "name")
        self.addRoleName(Qt.UserRole + 2, "materials")
        self.all_materials_dict = {}
        self._i18n_catalog = i18nCatalog("cura")

        self._update()

    def _update(self):

        # Perform standard check and reset if the check fails
        if not self._canUpdate():
            self.setItems([])
            return

        # Get updated list of favorites
        self._favorite_ids = self._material_manager.getFavorites()

        brand_item_list = []
        brand_group_dict = {}
        self.all_materials_dict = {}

        # Part 1: Generate the entire tree of brands -> material types -> spcific materials
        for root_material_id, container_node in self._available_materials.items():
            # Do not include the materials from a to-be-removed package
            if bool(container_node.getMetaDataEntry("removed", False)):
                continue

            # Add brands we haven't seen yet to the dict, skipping generics
            brand = container_node.getMetaDataEntry("brand", "")
            if brand.lower() == "generic":
                continue
            if brand not in brand_group_dict:
                brand_group_dict[brand] = {}

            # Add material types we haven't seen yet to the dict
            material_type = container_node.getMetaDataEntry("material", "")
            if material_type not in brand_group_dict[brand]:
                brand_group_dict[brand][material_type] = []

            # Now handle the individual materials
            item = self._createMaterialItem(root_material_id, container_node)
            brand_group_dict[brand][material_type].append(item)

        # Part 2: Organize the tree into models
        #
        # Normally, the structure of the menu looks like this:
        #     Brand -> Specific Material
        #
        # To illustrate, a branded material menu may look like this:
        #     ColorFabb┳ ColorFabb PLA
        #              ┣ ColorFabb ASA
        #              ┗ ...
        #
        for brand, material_dict in brand_group_dict.items():
            material_item_list = []
            brand_item = {
                "name": brand,
                "materials": BaseMaterialsModel(self),
            }

            for material_type, material_list in material_dict.items():
                # Sort materials by name
                material_list = sorted(material_list, key = lambda x: x["name"].upper())
                for material in material_list: # add individual materials to materials list one by one
                    material_item_list.append(material)
                    if material["name"] == "custom": # translate if it is custom
                       material["brand"] = self._i18n_catalog.i18nc("@label", "Custom")
                    self.all_materials_dict[material["name"]] = material

            if brand in ["Zaxe", "Custom"]: # we already have these separately.
                continue

            material_item_list = sorted(material_item_list, key = lambda x: x["description"].upper())
            brand_item["materials"].setItems(material_item_list)
            brand_item_list.append(brand_item)

        # Sort brand by name
        brand_item_list = sorted(brand_item_list, key = lambda x: x["name"].upper())
        self.setItems(brand_item_list)
        self.materialsChanged.emit()

    @pyqtProperty(QVariant, notify = materialsChanged)
    def materials(self):
        return self.all_materials_dict
