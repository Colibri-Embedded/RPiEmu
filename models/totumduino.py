#!/usr/bin/env python

from Queue import Queue, Empty
import threading
import time
from time import sleep

class TotumDuino:
	
	def __init__(self, fabtotum):
		self.fabtotum = fabtotum

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
			# force it to work with high load for nothing.
			sleep(10)
					
	##
	## UART0 transfer handler.
	## Used to handle G-Code commands, relay them to the physical FABTotum
	## model and to generate replies on the UART0
	##
	def uart0_transfer(self, msg):
		reply=''
		cmd = msg.split(" ")			
			
		if cmd[0] == 'G0':
			pass
		elif cmd[0] == 'G1':
			pass
		elif cmd[0] == 'G2':
			pass
		elif cmd[0] == 'G3':
			pass
		elif cmd[0] == 'G4':
			pass
		elif cmd[0] == 'G10':
			pass
		elif cmd[0] == 'G11':
			pass
		elif cmd[0] == 'G27':
			pass
		elif cmd[0] == 'G28':
			pass
		elif cmd[0] == 'G29':
			pass
		elif cmd[0] == 'G30':
			pass
		elif cmd[0] == 'G90':
			pass
		elif cmd[0] == 'G91':
			pass
		elif cmd[0] == 'G92':
			pass
		elif cmd[0] == 'M0':
			pass
		elif cmd[0] == 'M1':
			pass
		elif cmd[0] == 'M3':
			pass
		elif cmd[0] == 'M4':
			pass
		elif cmd[0] == 'M5':
			pass
		elif cmd[0] == 'M17':
			pass
		elif cmd[0] == 'M18':
			pass
		elif cmd[0] == 'M20':
			pass
		elif cmd[0] == 'M21':
			pass
		elif cmd[0] == 'M22':
			pass
		elif cmd[0] == 'M23':
			pass
		elif cmd[0] == 'M24':
			pass
		elif cmd[0] == 'M25':
			pass
		elif cmd[0] == 'M26':
			pass
		elif cmd[0] == 'M27':
			pass
		elif cmd[0] == 'M28':
			pass
		elif cmd[0] == 'M29':
			pass
		elif cmd[0] == 'M30':
			pass
		elif cmd[0] == 'M31':
			pass
		elif cmd[0] == 'M32':
			pass
		elif cmd[0] == 'M42':
			pass
		elif cmd[0] == 'M80':
			pass
		elif cmd[0] == 'M81':
			pass
		elif cmd[0] == 'M82':
			pass
		elif cmd[0] == 'M83':
			pass
		elif cmd[0] == 'M84':
			pass
		elif cmd[0] == 'M85':
			pass
		elif cmd[0] == 'M92':
			pass
		elif cmd[0] == 'M104':
			pass
		elif cmd[0] == 'M105':
			reply = " T:24.3 /0.0 B:24.8 /0.0 T0:24.3 /0.0 @:0 B@:0"
		elif cmd[0] == 'M106':
			pass
		elif cmd[0] == 'M107':
			pass
		elif cmd[0] == 'M109':
			pass
		elif cmd[0] == 'M114':
			pass
		elif cmd[0] == 'M115':
			pass
		elif cmd[0] == 'M117':
			pass
		elif cmd[0] == 'M119':
			pass
		elif cmd[0] == 'M126':
			pass
		elif cmd[0] == 'M127':
			pass
		elif cmd[0] == 'M128':
			pass
		elif cmd[0] == 'M129':
			pass
		elif cmd[0] == 'M140':
			pass
		elif cmd[0] == 'M150':
			pass
		elif cmd[0] == 'M190':
			pass
		elif cmd[0] == 'M200':
			pass
		elif cmd[0] == 'M201':
			pass
		elif cmd[0] == 'M202':
			pass
		elif cmd[0] == 'M203':
			pass
		elif cmd[0] == 'M204':
			pass
		elif cmd[0] == 'M205':
			pass
		elif cmd[0] == 'M206':
			pass
		elif cmd[0] == 'M207':
			pass
		elif cmd[0] == 'M208':
			pass
		elif cmd[0] == 'M209':
			pass
		elif cmd[0] == 'M218':
			pass
		elif cmd[0] == 'M220':
			pass
		elif cmd[0] == 'M221':
			pass
		elif cmd[0] == 'M226':
			pass
		elif cmd[0] == 'M240':
			pass
		elif cmd[0] == 'M250':
			pass
		elif cmd[0] == 'M280':
			pass
		elif cmd[0] == 'M300':
			pass
		elif cmd[0] == 'M301':
			pass
		elif cmd[0] == 'M302':
			pass
		elif cmd[0] == 'M303':
			pass
		elif cmd[0] == 'M304':
			pass
		elif cmd[0] == 'M350':
			pass
		elif cmd[0] == 'M351':
			pass
		elif cmd[0] == 'M400':
			pass
		elif cmd[0] == 'M401':
			pass
		elif cmd[0] == 'M402':
			pass
		elif cmd[0] == 'M500':
			pass
		elif cmd[0] == 'M501':
			pass
		elif cmd[0] == 'M502':
			pass
		elif cmd[0] == 'M503':
			pass
		elif cmd[0] == 'M540':
			pass
		elif cmd[0] == 'M600':
			pass
		elif cmd[0] == 'M605':
			pass
		elif cmd[0] == 'M665':
			pass
		elif cmd[0] == 'M666':
			pass
		elif cmd[0] == 'M700':
			pass
		elif cmd[0] == 'M701':
			pass
		elif cmd[0] == 'M702':
			pass
		elif cmd[0] == 'M703':
			pass
		elif cmd[0] == 'M704':
			pass
		elif cmd[0] == 'M705':
			pass
		elif cmd[0] == 'M706':
			pass
		elif cmd[0] == 'M710':
			pass
		elif cmd[0] == 'M711':
			pass
		elif cmd[0] == 'M712':
			pass
		elif cmd[0] == 'M713':
			pass
		elif cmd[0] == 'M714':
			pass
		elif cmd[0] == 'M720':
			pass
		elif cmd[0] == 'M721':
			pass
		elif cmd[0] == 'M722':
			pass
		elif cmd[0] == 'M723':
			pass
		elif cmd[0] == 'M724':
			pass
		elif cmd[0] == 'M725':
			pass
		elif cmd[0] == 'M726':
			pass
		elif cmd[0] == 'M727':
			pass
		elif cmd[0] == 'M728':
			pass
		elif cmd[0] == 'M729':
			pass
		elif cmd[0] == 'M730':
			pass
		elif cmd[0] == 'M731':
			pass
		elif cmd[0] == 'M732':
			pass
		elif cmd[0] == 'M734':
			pass
		elif cmd[0] == 'M740':
			pass
		elif cmd[0] == 'M741':
			pass
		elif cmd[0] == 'M742':
			pass
		elif cmd[0] == 'M743':
			pass
		elif cmd[0] == 'M744':
			pass
		elif cmd[0] == 'M745':
			pass
		elif cmd[0] == 'M747':
			pass
		elif cmd[0] == 'M750':
			pass
		elif cmd[0] == 'M751':
			pass
		elif cmd[0] == 'M752':
			pass
		elif cmd[0] == 'M753':
			pass
		elif cmd[0] == 'M754':
			pass
		elif cmd[0] == 'M760':
			pass
		elif cmd[0] == 'M761':
			pass
		elif cmd[0] == 'M762':
			pass
		elif cmd[0] == 'M763':
			pass
		elif cmd[0] == 'M764':
			pass
		elif cmd[0] == 'M765':
			pass
		elif cmd[0] == 'M766':
			pass
		elif cmd[0] == 'M767':
			pass
		elif cmd[0] == 'M780':
			pass
		elif cmd[0] == 'M781':
			pass
		elif cmd[0] == 'M782':
			pass
		elif cmd[0] == 'M783':
			pass
		elif cmd[0] == 'M784':
			pass
		elif cmd[0] == 'M785':
			pass
		elif cmd[0] == 'M786':
			pass
		elif cmd[0] == 'M787':
			pass
		elif cmd[0] == 'M788':
			pass
		elif cmd[0] == 'M789':
			pass
		elif cmd[0] == 'M790':
			pass
		elif cmd[0] == 'M791':
			pass
		elif cmd[0] == 'M792':
			pass
		elif cmd[0] == 'M793':
			pass
		elif cmd[0] == 'M907':
			pass
		elif cmd[0] == 'M908':
			pass
		elif cmd[0] == 'M928':
			pass
		elif cmd[0] == 'M999':
			pass

		else:
			return None

		
		return 'ok'+reply+'\r\n'




