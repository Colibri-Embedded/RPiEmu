#!/usr/bin/env python
# -*- coding: utf-8; -*-
#
# (c) 2016 Colibri-Embedded, Daniel Kesler <kesler.daniel@gmail.com>
#
# This file is part of RPiEMU.
#
# RPiEMU is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# RPiEMU is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with RPiEMU.  If not, see <http://www.gnu.org/licenses/>.

# Import standard python module
from time import sleep
from threading import Thread

# Import external modules
from RPiEmu import QemuInstance, UARTLineParser

# Import internal modules
from models.example import UARTPeripheral

def main():
    rpi     = QemuInstance()
    example = UARTPeripheral()
    parser  = UARTLineParser(qemu=rpi, line_handler=example.uart0_transfer)
    
    # Start
    rpi.start()
    example.run()
    parser.start()

    # Finish
    parser.loop()
    example.finish()

if __name__ == "__main__":
    main()
