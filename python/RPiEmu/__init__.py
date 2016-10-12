#/usr/bin/env python

## @package qemu
# QEMU wrapper.
#
# TCP connection to QEMU's serial port.

import socket
import time
from threading import Event, Thread, RLock
try:
    import queue
except ImportError:
    import Queue as queue

class UARTLineParser:
    
    def __init__(self, qemu, line_handler):
        self.qemu = qemu
        self.line_handler = line_handler
        
    def __receiver_thread(self):
        chunks=''
        
        while True:
            # Receive data from QEMU UART
            try:
                data = self.qemu.serial_receive()
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
                            reply = self.line_handler( line.rstrip() )
                            # Send a UART reply back to QEMU UART
                            if reply:
                                self.qemu.serial_send(reply)
                                
                    # Clear the local serial buffer
                    chunks=''
                    
    def start(self):
        self.receiver_thread = Thread( target=self.__receiver_thread )
        self.receiver_thread.start()
        
    def loop(self):
        self.receiver_thread.join()

class UARTInstance:
    def __init__(self):
        self.rxq = queue.Queue() # Receiver Queue
        self.txq = queue.Queue() # Transmitter Queue
    
    def put(self, msg):
        print 'uart0.put', msg
        self.txq.put(msg)
        
    def get(self):
        msg = self.rxq.get()
        print 'uart0.get', msg
        return msg
        
    def put_rx(self, msg):
        self.rxq.put(msg)
        
    def get_tx(self):
        return self.txq.get()

class QemuInstance:
    """demonstration class only
     - coded for clarity, not efficiency
    """
    BUFFER_SIZE = 1024

    def __init__(self, sdcard_image = '../sdcard.img', use_queues = False, sock=None):
        
        self.hw_model = None
        self.rpiqemu_path = './scripts'
        self.sdcard_file = '../sdcard.img'
        self.serial_port = 4444
        
        self.receiver_thread = None
        self.sender_thread = None
        self.use_queues = use_queues
        
        if use_queues:
            self.uart0 = UARTInstance()
        
        if sock is None:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        else:
            self.sock = sock

    def bind(self, hw_model):
        self.hw_model = hw_model

    def connect(self, host, port):
        try_to_connect = 15
        
        # Wait for Qemu to boot-up and initiate the TCP connection
        # Qemu acts as a TCP server and will pause further execution
        # until a connection is made.
        
        while try_to_connect:
            try:
                self.sock.connect((host, port))
                print "QEMU.uart: connected"
                
                return
            except socket.error as msg:
                try_to_connect -= 1
                if try_to_connect:
                    print "QEMU.uart: retry to connect"
                    time.sleep(1)
                else:
                    print "QEMU.uart: giving up to connect"

    def disconnect(self):
        if self.sock is not None:
            self.sock.close()
            self.sock = None

    def serial_send(self, msg):
        data = msg.encode('latin-1')
        sent = self.sock.send( data )

    def serial_receive(self):
        try:
            data = self.sock.recv(self.BUFFER_SIZE)
        except socket.error, (value,message): 
            raise Exception('Socket Error')
        
        if data == b'':
            return data
        
        return data.replace('\x00','')

    def __uart_receive_thread(self):
        import cStringIO
        stream = cStringIO.StringIO()
        
        while True:
            try:
                data = self.serial_receive()
            except Exception as e:
                print str(e)
                break
                
            # Accumulate serial data
            if data:
                stream.write(data)
                print '[{0}] - "{1}"'.format(data, stream.getvalue() )
                
            content = stream.getvalue()
            if '\n' in content:
                #~ content = content.rstrip()
                #~ # Split the chunks into lines
                keepLast = ''
                if content[-1] == '\n':
                    lines = content.replace('\r','').split('\n')
                    keepLast = lines[-1]
                    lines = lines[:-1]
                
                #~ # Send each line one by one to the Totumduino model
                for line in lines:
                    if line:
                        #~ # print('>>',line.rstrip())
                        self.uart0.put_rx(line)
                            
                #~ # Clear the local serial buffer
                #~ chunks=''
                stream = cStringIO.StringIO()
                stream.write(keepLast)
        
    def __uart_send_thread(self):
        
        while True:
            msg = self.uart0.get_tx()
            print '__uart_send_thread: ', msg
            self.serial_send(msg)

    def start(self):
        import os
        
        curr_pid = os.getpid()
        print "pid:", curr_pid
        
        command = 'cd {0};'.format(self.rpiqemu_path);
        command += './rpi-bootloader-qemu.sh -sdimg {0} -tcpserial {1} -modelpid {2}'.format(self.sdcard_file, self.serial_port, curr_pid)
        
        os.system(command + ' &')
        
        self.connect('127.0.0.1', self.serial_port)
        
        if self.use_queues:
            self.receiver_thread = Thread( target=self.__uart_receive_thread )
            self.receiver_thread.start() 
            
            self.sender_thread = Thread( target=self.__uart_receive_thread )
            self.sender_thread.start() 
        
        
    def stop(self):
        pass

    def loop(self):
        if self.use_queues:
            self.receive_thread.join()
            self.sender_thread.join()

############### scrap code ###########
        #~ chunks = []
        #~ bytes_recd = 0
        #~ while bytes_recd < MSGLEN:
            #~ chunk = self.sock.recv(min(MSGLEN - bytes_recd, 2048))
            #~ if chunk == b'':
                #~ raise RuntimeError("socket connection broken")
            #~ chunks.append(chunk)
            #~ bytes_recd = bytes_recd + len(chunk)
        #~ return b''.join(chunks)

        #print("socket.sent =", sent)
        #while totalsent < len(msg):
        #sent = self.sock.send(msg[totalsent:])
        #    if sent == 0:
        #        raise RuntimeError("socket connection broken")
        #    totalsent = totalsent + sent
