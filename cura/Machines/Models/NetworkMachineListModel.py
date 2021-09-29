from PyQt5.QtCore import pyqtSignal, QModelIndex, QVariant, QTimer

from UM.Application import Application
from UM.Logger import Logger
from UM.Qt.ListModel import ListModel

from cura.NetworkMachineManager import NetworkMachineManager

#
# QML Model for network machines
#
class NetworkMachineListModel(ListModel):

    def __init__(self, parent = None):
        super().__init__(parent)

        self._application = Application.getInstance()
        self._controller = self._application.getController()
        self._machine_manager = self._application.getMachineManager()
        self._network_machine_manager = self._application.getNetworkMachineManager()
        self._application.globalContainerStackChanged.connect(self._delayedFilter)

        # to be able to filter machines according to stage
        self._controller.activeStageChanged.connect(self._onActiveStageChanged)

        self._network_machine_manager.machineAdded.connect(self._itemAdded)
        self._network_machine_manager.machineRemoved.connect(self._itemRemoved)
        self._network_machine_manager.machineNewMessage.connect(self._itemUpdate)
        self._network_machine_manager.machineUploadProgress.connect(self._itemUploadProgress)

        self._allItems = []
        self._filterStr = self._machine_manager.activeMachineId.replace("+", "plus").lower()
        self._previousFilterStr = None
        self._filtered = False # don't filter at the beginning

    temperatureProgressEnabled = False

    # general events
    itemAdded = pyqtSignal(int)
    itemRemoved = pyqtSignal(int)
    cleared = pyqtSignal()

    # update events
    tempChange = pyqtSignal(str, int)
    nameChange = pyqtSignal(str, str)
    calibrationProgress = pyqtSignal(str, float)
    printProgress = pyqtSignal(str, float)
    uploadProgress = pyqtSignal(str, float)
    tempProgress = pyqtSignal(str, float)
    materialChange = pyqtSignal(str, str)
    nozzleChange = pyqtSignal(str, str)
    fileChange = pyqtSignal(str, str, float, str)
    stateChange = pyqtSignal(str, QVariant)
    pinChange = pyqtSignal(str, bool)
    spoolChange = pyqtSignal(str, bool, float, str)

    def _getItem(self, networkMachine):
        item = {
            "mID": networkMachine.id,
            "mName": networkMachine.name,
            "mIP": networkMachine.ip,
            "mMaterial": networkMachine.material,
            "mNozzle": str(networkMachine.nozzle),
            "mDeviceModel": networkMachine.deviceModel,
            "mFWVersion": ".".join(map(str, networkMachine.fwVersion)),
            "mPrintingFile": networkMachine.printingFile,
            "mElapsedTime": networkMachine.elapsedTime,
            "mEstimatedTime": networkMachine.estimatedTime,
            "mStartTime": networkMachine.startTime,
            "mHasPin": networkMachine.hasPin,
            "mHasNFCSpool": networkMachine.hasNFCSpool,
            "mFilamentRemaining": networkMachine.filamentRemaining,
            "mFilamentColor": networkMachine.filamentColor,
            "mHasSnapshot": networkMachine.hasSnapshot,
            "mHasFWUpdate": self._compareVersion(networkMachine),
            "mSnapshot": networkMachine.snapshot,
            "mIsLite": networkMachine.isLite,
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
        version = self._network_machine_manager.DEVICE_VERSIONS[networkMachine.deviceModel]["version"]
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
            self.nozzleChange.emit(uuid, str(eventArgs.machine.nozzle))
            self._itemUpdated(uuid, "mNozzle", str(eventArgs.machine.nozzle))
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
        if message["event"] in ["hello", "spool_data_change"]:
            self.spoolChange.emit(uuid, bool(eventArgs.machine.hasNFCSpool), eventArgs.machine.filamentRemaining, eventArgs.machine.filamentColor)
            self._itemUpdated(uuid, "mHasNFCSpool", eventArgs.machine.hasNFCSpool)
            self._itemUpdated(uuid, "mFilamentRemaining", eventArgs.machine.filamentRemaining)
            self._itemUpdated(uuid, "mFilamentColor", eventArgs.machine.filamentColor)

    def _itemUploadProgress(self, eventArgs):
        self.uploadProgress.emit(eventArgs.machine.id, float(eventArgs.progress / 100))

    def _itemAdded(self, networkMachine, nm = None):
        if nm is None: # first time adding on connect to device (New)
            nm = self._getItem(networkMachine)
            index = len(self._allItems)
            self._allItems.insert(index, nm)

        if not self._filtered or nm["mDeviceModel"] == self._filterStr: # add to visible list
            index = len(self._items)
            self.beginInsertRows(QModelIndex(), index, index)
            self._items.insert(index, nm)
            self.endInsertRows()
            self.itemAdded.emit(index)

    def _itemRemoved(self, mId, nm = None):
        if nm is None: # real deletion nm is gone
            index = self._findInAll("mID", mId)
            if index == -1:
                return
            del self._allItems[index]

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
        # update all items (which may not be visible atm)
        index = self._findInAll("mID", mId)
        if index == -1:
            return # if we don't have it in all items visible items shouldn't have it.
        self._allItems[index][property] = value

        # also update visible ones
        index = self.find("mID", mId)
        if index == -1:
            return
        self.setProperty(index, property, value)        

    def _findInAll(self, property, value):
        index = -1
        for item in self._allItems:
            index += 1
            if item[property] == value:
                break
        return index

    def _delayedFilter(self):
        QTimer.singleShot(100, self._filter)

    def _filter(self):
        self._filterStr = self._machine_manager.activeMachineId.replace("+", "plus").lower()
        if self._filtered:
            if self._previousFilterStr == self._filterStr:
                return
            self._previousFilterStr = self._filterStr
            for nm in self._allItems:
                if nm["mDeviceModel"] == self._filterStr:
                    self._itemAdded(None, nm)
                else:
                    self._itemRemoved(nm["mID"], nm)
        else: # add all without filter
            for nm in self._allItems:
                if self.find("mID", nm["mID"]) == -1:
                    self._itemAdded(None, nm)
                
    def _onActiveStageChanged(self):
        # call _onActiveStageChangedDelayed to resolve blocking stage change
        if self._controller.getActiveStageName() == "NetworkMachineList":
            QTimer.singleShot(1000, self._onActiveStageChangedDelayed)

    def _onActiveStageChangedDelayed(self):
        if self._controller.getActiveStageName() == "NetworkMachineList":
            self._previousFilterStr = None # reset
            self.clear()
            self.cleared.emit()
            self._filtered = True
            self._filter()

