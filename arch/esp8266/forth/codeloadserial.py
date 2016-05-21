import serial
import sys
import time

port = serial.Serial(
    port='COM3',
    baudrate=115200,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,	
    bytesize=serial.EIGHTBITS,
    timeout=5)

if len(sys.argv) < 2:
    print('Usage %s <file1.forth> ... [fileN.forth]' % (sys.argv[0]))
    sys.exit()

def upload(path): 
    with open(path) as source:
        for line in source.readlines():
            line = line.strip()
            if not line: continue
            if len(line) > 128:
                raise 'Line is too long: %s' % (line)
            #print('sending: ' + line)
            port.write(line)        
            port.write('\n')
            time.sleep(0.05)
            response_buffer = []        
            while port.inWaiting() > 0:
                response_buffer.append(port.read(1))
            response = ''.join(response_buffer)
            sys.stdout.write(response)
            if 'undefined word' in response.lower():
                print 'ABORTED'
                sys.exit()                        

for path in sys.argv[1:]:
    print('Uploading %s' % path)
    upload(path)
               