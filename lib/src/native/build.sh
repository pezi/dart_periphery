#!/bin/bash

echo "Build native library for dart_periphery"

BITNESS=`getconf LONG_BIT`

if ! command -v gcc  &> /dev/null
then
    echo "gcc not installed!"
    exit 1 
fi

DIR="/usr/local/include/periphery/"
if [ ! -d "$DIR" ]; then
    # Take action if $DIR exists. #
    echo "Missing c-periphery include files! Is c-periphery installed?"
    exit 1
  
fi


# do not work for Armbian 64
# ldconfig -p | grep periphery &> /dev/null
#
# if [ $? -ne 0 ]; then
#    echo "periphery lib is not installed!" 
#    exit 1
# fi

FILE="/usr/local/lib/libperiphery.so"
if [ ! -f "$FILE" ]; then
    echo "periphery lib is not installed!" 
    exit 1
fi

gcc -I/usr/local/include/periphery/  -Wall -fPIC -O3 -shared gpio.c serial.c i2c.c led.c pwm.c version.c spi.c mmio.c -lperiphery  -lpthread -o dart_periphery_${BITNESS}.1.0.0.so

