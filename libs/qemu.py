#/usr/bin/env python3
## @package qemu
# QEMU wrapper.
#
# TCP connection to QEMU's serial port.

import socket

class QemuSocket:
	"""demonstration class only
	 - coded for clarity, not efficiency
	"""
	BUFFER_SIZE = 1024

	def __init__(self, sock=None):
		if sock is None:
			self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		else:
			self.sock = sock

	def connect(self, host, port):
		self.sock.connect((host, port))

	def disconnect(self):
		if self.sock is not None:
			self.sock.close()
			self.sock = None

	def serial_send(self, msg):
		#totalsent = 0
		data = msg.encode('latin-1')
		sent = self.sock.send( data )
		#print("socket.sent =", sent)
		#while totalsent < len(msg):
		#sent = self.sock.send(msg[totalsent:])
		#	if sent == 0:
		#		raise RuntimeError("socket connection broken")
		#	totalsent = totalsent + sent

	def serial_receive(self):
		try:
			data = self.sock.recv(self.BUFFER_SIZE)
		except socket.error, (value,message): 
			raise Exception('Socket Error')
		
		if data == b'':
			return data
		
		return data.replace('\x00','')
        #~ chunks = []
        #~ bytes_recd = 0
        #~ while bytes_recd < MSGLEN:
            #~ chunk = self.sock.recv(min(MSGLEN - bytes_recd, 2048))
            #~ if chunk == b'':
                #~ raise RuntimeError("socket connection broken")
            #~ chunks.append(chunk)
            #~ bytes_recd = bytes_recd + len(chunk)
        #~ return b''.join(chunks)


#s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#TCP_IP = '127.0.0.1'
#TCP_PORT = 4444
#BUFFER_SIZE = 1024

#MESSAGE = "Hello, World!"
#s.connect((TCP_IP, TCP_PORT))

#while True:
#	data = s.recv(BUFFER_SIZE)
#	print("received data:", data)
#
#s.close()
