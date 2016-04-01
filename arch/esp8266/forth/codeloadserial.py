import serial
import sys
import time

port = serial.Serial(
    port='COM3',
    baudrate=74880,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,	
    bytesize=serial.EIGHTBITS)

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
            port.write(line)        
            port.write('\n')
            time.sleep(0.1)
            while port.inWaiting() > 0:
                sys.stdout.write(port.read(1))

for path in sys.argv[1:]:
    print('Uploading %s' % path)
    upload(path)
               