from PyQt5 import QtNetwork
from PyQt5.QtCore import pyqtSignal, pyqtProperty, QObject, QVariant  # For communicating data and events to Qt.

from UM.Logger import Logger

import json


class BroadcastReceiver(QObject):

    _port = 9295

    _socket = None

    broadcastReceived = pyqtSignal(dict)

    def __init__(self, parent = None):
        try:
            super().__init__(parent)
            Logger.log("w", "initializing BroadcastReceiver")
            self.udpSocket = QtNetwork.QUdpSocket()
            self.udpSocket.bind(self._port)
            self.udpSocket.readyRead.connect(self.processPendingDatagrams)
        except Exception as ex:
            Logger.log("e","unexpected error %s" % ex)
            self._stop = True

    def processPendingDatagrams(self):
        try:
            datagram, host, port = self.udpSocket.readDatagram(self.udpSocket.pendingDatagramSize())
            msg = json.loads(str(datagram, encoding='ascii'))
            self.broadcastReceived.emit(msg)
            #Logger.log("d", "received msg: [%s]" % msg)
        except Exception as ex:
            Logger.log("e","unexpected error %s" % ex)

    def stop(self):
        self.udpSocket.close()