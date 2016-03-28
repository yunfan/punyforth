import sys
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(('192.168.0.13', 8888))

with open(sys.argv[1]) as source:
    for line in source.readlines():
        if len(line) > 128:
            raise 'Line is too long: %s' % (line)
        sock.send(line)        
        sock.send('\n')
        print(sock.recv(128))
        
sock.close()        
            
