import sys
sys.path.append("C:\\Users\\irvinelabuser\\Infineon\\Tools\\AIROC-Bluetooth-Test-and-Debug-Tool\\1.3.0.3116\\clients\\python\\src") # check this path before running

from infineon.airocbluetoothtool.client import client
from infineon.airocbluetoothtool.service import DEVICE_TYPE_UART

import pyvisa
import time

from subprocess import Popen

outfile = open('test.txt','w')
process = Popen("C:\\Users\\irvinelabuser\\Documents\\Playground\\scratch.bat", stdout=outfile)
stdout, stderr = process.communicate()

read_file = open('test.txt', 'r')

print(read_file.read())