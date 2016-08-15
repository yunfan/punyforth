#!/bin/sh
THEPORT=${1:-$ESPPORT}
if [ -z "$THEPORT" ]
	then
		echo "Port definition missing. Either give command-line parameter like '$0 /dev/usb000' or set environment variable ESPPORT"
		exit 1
fi

python esptool.py -p $THEPORT write_flash -fs 32m -fm dio -ff 40m 0x00000 rboot.bin 0x1000 blank_config.bin 0x2000 punyforth.bin 0x51000 uber.forth

