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

import threading
import time

class UARTPeripheral:
	
	def __init__(self):
		self.running = False
	
	##
	## Thread starting
	##
	def run(self):
		self.main_thread = threading.Thread(target=self.main_loop)
		self.running = True
		self.main_thread.start()

	##
	## Thread joining
	##
	def finish(self):
		self.running = False
		self.main_thread.join()
		
	##
	## Main loop
	##
	def main_loop(self):
		#while self.running or not self.rx_queue.empty():
		while self.running:
			# For now used to relax the CPU as the while loop would 
			# force it to work with high load for nothing.
			time.sleep(10)
					
	##
	## UART0 transfer handler.
	##
	def uart0_transfer(self, msg):
		print ">>", msg
		return 'ok\r\n'




