#!/usr/bin/env python3

from queue import Queue, Empty
import threading
import time
from time import sleep

class TotumDuino:
	
	def __init__(self, fabtotum):
		self.fabtotum = fabtotum
		#self.rx_queue = Queue(16)
		#self.tx_queue = Queue(16)

	def run(self):
		self.t1 = threading.Thread(target=self.fablin_main)
		self.running = True
		self.t1.start()
		
	def finish(self):
		self.running = False
		self.t1.join()

	##
	## Main loop of fablin firmware model.
	## Used to simulate time dependent processes, like motor movement
	## temperature changes...
	##
	def fablin_main(self):
		#while self.running or not self.rx_queue.empty():
		while self.running:
			# For now used to relax the CPU as the while loop would 
			# force it to work nad high load for nothing.
			sleep(1)
					
	##
	## UART0 transfer handler.
	## Used to handle G-Code commands, relay them to the physical FABTotum
	## model and to generate replies on the UART0
	##
	def uart0_transfer(self, msg):
		reply=''
		cmd = msg.split(" ")
		if cmd[0] == 'M728':
			pass
			
		elif cmd[0] == 'M105':
			return "ok T:24.3 /0.0 B:24.8 /0.0 T0:24.3 /0.0 @:0 B@:0\r\n"
			
		elif cmd[0] == 'M701':
			return None
			
		elif cmd[0] == 'M702':
			return None
			
		elif cmd[0] == 'M703':
			pass
			
		else:
			return None
		
		return 'ok'+reply+'\r\n'




