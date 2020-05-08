from PyQt5.QtCore import pyqtSignal, QThread, QObject
from UM.Logger import Logger

import http.client
import json

class ZaxeVersionEventArgs():

    deviceModel = None

    version  = None

    def __init__(self, deviceModel, version):
        self.deviceModel = deviceModel
        self.version = version

class ZaxeVersion(QThread, QObject):

    versionEvent = pyqtSignal(ZaxeVersionEventArgs)

    def __init__(self, path, deviceModel):
        QObject.__init__(self)
        self.path = path
        self.deviceModel = deviceModel
        self.daemon = True
        self.response = ""

    def run(self):
        try:
            Logger.log("d", "Checking version: %s..." % self.path)
            connection = http.client.HTTPConnection("software.zaxe.com", 80, timeout=5)
            connection.request("GET", self.path)
            response = connection.getresponse()
            self.response = response.read().decode('utf-8')
            Logger.log("d", "Status: %d" % response.status)
            Logger.log("d", "Response: %s" % self.response)
            Logger.log("d", "Done version check for: %s" % self.path)
            if response.status == 200:
                self.emit_success()
        except:
            Logger.log("w", "Can not connect to update server")

    def emit_success(self):
        jsonResponse = json.loads(self.response)
        v = [int(v) for v in jsonResponse["version"].split(".")]
        self.versionEvent.emit(ZaxeVersionEventArgs(self.deviceModel, v))

