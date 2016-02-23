#!/usr/bin/env python

import os, Queue
from time import sleep

# Import FABEmu specific packages
from libs.qemu import QemuSocket
from models.totumduino import TotumDuino
from models.fabtotum import FABTotum

# Start Qemu with Serial over TCP (on port 4444)
curr_pid = os.getpid()
print "pid:",curr_pid
os.system('cd rpi-qemu;./rpi-bootloader-qemu.sh -sdimg ../sdcard.img -tcpserial 4444 -modelpid ' + str(curr_pid) + ' &')

# Wait for Qemu to boot-up and initiate the TCP connection
# Qemu acts as a TCP server and will pause further execution
# until a connection is made.
sleep(3)

print("=== Starting FABEmu v0.1 ===")

# Qemu python wrapper that connects to the TCP server
qemu = QemuSocket()
qemu.connect('127.0.0.1', 4444)

# FABTotum model
ft = FABTotum()
# Totumduino model
td = TotumDuino(ft)

# Start a TD thread
td.run()

print("* Totumduino thread started")

chunks=''

while True:
	# Receive data from QEMU UART
	try:
		data = qemu.serial_receive()
	except Exception as e:
		break
	
	# Accumulate serial data
	if data:
		chunks += data
	
	if chunks:
		# Check whether there is a line end at the end of chunks
		if chunks[-1] == '\n':

			chunks = chunks.rstrip()
			# Split the chunks into lines
			lines = chunks.replace('\r','').split('\n')
			# Send each line one by one to the Totumduino model
			for line in lines:
				if line:
					print('>>',line.rstrip())
					# Call the Totumdino model UART0 handler
					reply = td.uart0_transfer( line.rstrip() )
					# Send a UART reply back to QEMU UART
					if reply:
						qemu.serial_send(reply)
						
			# Clear the local serial buffer
			chunks=''

# Finish the TD thread
td.finish()
