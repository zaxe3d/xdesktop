# Copyright (c) 2018 Ultimaker B.V.
# Cura is released under the terms of the LGPLv3 or higher.

from PyQt5.QtCore import Qt, pyqtSlot, pyqtSignal, QModelIndex, QVariant

from UM.Application import Application
from UM.Logger import Logger
from UM.Qt.ListModel import ListModel

from cura.NetworkMachineManager import NetworkMachineManager

import json


#
# QML Model for network machines
#
class NetworkMachineListModel(ListModel):

    def __init__(self, parent = None):
        super().__init__(parent)

        self._application = Application.getInstance()
        self._machine_manager = self._application.getNetworkMachineManager()

        self._machine_manager.machineAdded.connect(self._itemAdded)
        self._machine_manager.machineRemoved.connect(self._itemRemoved)
        self._machine_manager.machineNewMessage.connect(self._itemUpdate)
        self._machine_manager.machineUploadProgress.connect(self._itemUploadProgress)

    temperatureProgressEnabled = False

    # general events
    itemAdded = pyqtSignal(int)
    itemRemoved = pyqtSignal(int)

    # update events
    tempChange = pyqtSignal(str, int)
    nameChange = pyqtSignal(str, str)
    calibrationProgress = pyqtSignal(str, float)
    printProgress = pyqtSignal(str, float)
    uploadProgress = pyqtSignal(str, float)
    tempProgress = pyqtSignal(str, float)
    materialChange = pyqtSignal(str, str)
    nozzleChange = pyqtSignal(str, float)
    fileChange = pyqtSignal(str, str, float, str)
    stateChange = pyqtSignal(str, QVariant)
    pinChange = pyqtSignal(str, bool)

    def _getItem(self, networkMachine):
        item = {
            "mID": networkMachine.id,
            "mName": networkMachine.name,
            "mIP": networkMachine.ip,
            "mMaterial": networkMachine.material,
            "mNozzle": networkMachine.nozzle,
            "mDeviceModel": networkMachine.deviceModel,
            "mFWVersion": networkMachine.fwVersion,
            "mPrintingFile": networkMachine.printingFile,
            "mElapsedTime": networkMachine.elapsedTime,
            "mEstimatedTime": networkMachine.estimatedTime,
            "mStartTime": networkMachine.startTime,
            "mHasPin": networkMachine.hasPin,
            "mHasSnapshot": networkMachine.hasSnapshot,
            "mHasFWUpdate": self._compareVersion(networkMachine),
            "mSnapshot": networkMachine.snapshot,
            "mStates": networkMachine.getStates()
        }


        return item


    # machine update start

    def _onTempChange(self, uuid, extActual, extTarget, bedActual, bedTarget):
        extActual = min(extActual, extTarget)
        bedActual = min(bedActual, bedTarget)
        extRatio = 1
        bedRatio = 1
        if extTarget > 0:
            extRatio =  float(extActual) / float(extTarget)
        if bedTarget > 0:
            bedRatio = float(bedActual) / float(bedTarget)
        percentage = int(extRatio * 50) + int(bedRatio * 50)

        self.tempChange.emit(uuid, min(100, percentage))

    def _onFileChange(self, uuid, networkMachine):
        self.fileChange.emit(
            uuid,
            networkMachine.printingFile,
            networkMachine.startTime,
            networkMachine.estimatedTime
        )
        self._itemUpdated(uuid, "mPrintingFile", networkMachine.printingFile)
        self._itemUpdated(uuid, "mStartTime", networkMachine.startTime)
        self._itemUpdated(uuid, "mEstimatedTime", networkMachine.estimatedTime)

    def _compareVersion(self, networkMachine):
        version = self._machine_manager.DEVICE_VERSIONS[networkMachine.deviceModel]["version"]
        if version > networkMachine.fwVersion:
            Logger.log("d", "[%s] has FW update available" % networkMachine.name)
            return True
        return False


    # machine update end

    def _itemUpdate(self, eventArgs):
        uuid = eventArgs.machine.id
        message = eventArgs.message['message']

        if message['event'] == "temperature_change":
            # new firmware calculates temperature on machine it self
            if self.temperatureProgressEnabled:
                return
            self._onTempChange(
                uuid,
                float(message['ext_actual']),
                float(message['ext_target']),
                float(message['bed_actual']),
                float(message['bed_target'])
            )
        elif message['event'] == "calibration_progress":
            self.calibrationProgress.emit(uuid, float(message["progress"]) / 100)
        elif message['event'] == "print_progress":
            self.printProgress.emit(uuid, float(message["progress"]) / 100)
        elif message['event'] == "new_name":
            self.nameChange.emit(uuid, message["name"])
            self._itemUpdated(uuid, "mName", message["name"])
        if message['event'] in ["material_change", "hello"]:
            self.materialChange.emit(uuid, eventArgs.machine.material)
            self._itemUpdated(uuid, "mMaterial", eventArgs.machine.material)
        if message['event'] in ["nozzle_change", "hello"]:
            self.nozzleChange.emit(uuid, eventArgs.machine.nozzle)
            self._itemUpdated(uuid, "mNozzle", eventArgs.machine.nozzle)
        if message["event"] == "temperature_progress":
            self.temperatureProgressEnabled = True
            self.tempProgress.emit(uuid, float(message["progress"]) / 100)
        if message['event'] in ["start_print", "hello"]:
            self._onFileChange(uuid, eventArgs.machine)
        if message['event'] in ["states_update", "hello"]:
            states = eventArgs.machine.getStates()
            self.stateChange.emit(uuid, states)
            self._itemUpdated(uuid, "mStates", states)
        if message["event"] in ["pin_change", "hello"]:
            self.pinChange.emit(uuid, bool(eventArgs.machine.hasPin))
            self._itemUpdated(uuid, "mHasPin", eventArgs.machine.hasPin)

    def _itemUploadProgress(self, eventArgs):
        self.uploadProgress.emit(eventArgs.machine.id, float(eventArgs.progress / 100))

    def _itemAdded(self, networkMachine):
        index = len(self._items)
        self.beginInsertRows(QModelIndex(), index, index)
        self._items.insert(index, self._getItem(networkMachine))
        self.endInsertRows()
        self.itemAdded.emit(index)

    def _itemRemoved(self, mId):
        index = self.find("mID", mId)
        if index == -1:
            return
        self.beginRemoveRows(QModelIndex(), index, index)
        del self._items[index]
        self.endRemoveRows()
        self.itemRemoved.emit(index)

    ## Updates model item's property
    #  Use this to update model item's less updated properties like
    #  states, name or nozzle. Because we directly update the
    #  network machine it self via listening signals. But if we send the
    #  network list to the background, we rerender items from the model
    #  so it doesn't get updated properly if we don't update it from here.
    #   \param mId machine id
    #   \property property name
    #   \value valuea of the intended property
    def _itemUpdated(self, mId, property, value):
        index = self.find("mID", mId)
        if index == -1:
            return
        self.setProperty(index, property, value)

