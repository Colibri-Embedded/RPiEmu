#!/usr/bin/env python

import os, Queue
import sys
from time import sleep
from threading import Thread

from libs.qemu import QemuInstance, UARTLineParser

# External

if len(sys.argv) > 1:
    print "ARGS:", str(sys.argv)
    sys.path.append(os.path.dirname( sys.argv[1] ))
    
########################################################################

print("=== Starting RPiEmu v0.5 ===")

# Qemu python wrapper that connects to the TCP server
rpi = QemuInstance()
rpi.start()


#####################################################

from models.totumduino import TotumDuino
from models.fabtotum import FABTotum

# FABTotum model
ft = FABTotum()

# Totumduino model
td = TotumDuino(ft)

# Start a TD thread
td.run()

print("* Totumduino thread started")

# UART line parser
parser = UARTLineParser(qemu=rpi, line_handler=td.uart0_transfer)
parser.start()

parser.loop()

# Finish the TD thread
td.finish()
