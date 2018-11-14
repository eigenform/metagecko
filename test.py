#!/usr/bin/python

import spidev
import sys

# First byte is ignored (slave returns 0xEE)
msg = [ 0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80 ]

spi = spidev.SpiDev()
spi.open(0,1)
spi.mode = 0b00
spi.max_speed_hz = 10000000
spi.bits_per_word = 8

resp = spi.xfer(msg)

output = []
for i in resp:
    output.append(hex(i))
print(output)
