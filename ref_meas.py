import sys
sys.path.append("C:\\Users\\irvinelabuser\\Infineon\\Tools\\AIROC-Bluetooth-Test-and-Debug-Tool\\1.3.0.3116\\clients\\python\\src") # check this path before running

from infineon.airocbluetoothtool.client import client
from infineon.airocbluetoothtool.service import DEVICE_TYPE_UART

import pyvisa
import time

###############################
## initialize airoc bluetool ##
###############################
print("Please ensure that airocbluetoothtoolserver.exe is running!")
pauser = input("Press enter to continue...")

print ("Please enter the COM port number of your device in the following format")
port = input("COM#\n")

# open session
session = client.connect('localhost', 1234)
print ("Connected!")

# open device
device = session.open_device(port, DEVICE_TYPE_UART)
print("Sending Reset...")

# send HCI Reset
device.send_hci_command_by_name('Reset')
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

#####################
## initialize file ##
#####################
file = open("Reference Measurements and 20 dBc limits.txt", "w")
file.write("PHY CHANNEL:\tRef level\t20 dBc limit\n")
file.close()
file = open("Reference Measurements and 20 dBc limits.txt", "a")

############################
## initialize flash drive ##
############################
print("Please insert flash drive and wait for any drivers to install...")
pauser = input("Press enter to continue...")

print("Please input the path of the directory in which you would like your results to be saved")
print("Use the full path name! (ex. F:\\\\...)")
result_path = input("Path: ")

#######################
## initialize specan ##
#######################
print ("Please input the appropriate offset for your specan")
print("Currently: Rack Specan = 11.7 dB; Cart Specan = ??")
print("Use the following format: 11.7 dB")
offset = input("Offset: ")

rm = pyvisa.ResourceManager()
inst_list = rm.list_resources()
print(inst_list)
print ("Please select your instrument by copying it's address below")
print("Rack Specan Agilent ID = MY49431636; Cart Specan Agilent ID = MY49431706")
instr = input("Instrument address here: ")
specan = rm.open_resource(instr)
print(specan.query('*IDN?'))
specan.query('*opc?')

specan.write('*rst')
specan.query('*opc?')

print("Setting up specan...")

# set attenuation level
specan.write('pow:att 18')
specan.write('*opc?')
specan.write('disp:wind:trac:y:rlev 20 dBm')
time.sleep(5)
specan.write('*opc?') # query is interrupted for some reason

# offset
specan.write(f'disp:wind:trac:y:rlev:offs {offset}')
specan.query('*opc?')

# rbw 100 kHz
specan.write('band 100 kHz')
specan.query('*opc?')

# vbw 300 kHz
specan.write('band:vid 300 kHz')
specan.query('*opc?')

# detector auto
specan.write('det:trac1:auto on')
specan.query('*opc?')

# trace max hold
specan.write('trac:type maxh')
specan.query('*opc?')

# sweep time auto
specan.write('swe:time:auto on')
specan.query('*opc?')

# sweep points 2001
specan.write('swe:poin 2001')
specan.query('*opc?')

# set to continuous measurement
specan.write('init:cont on')
specan.query('*opc?')

# restart
specan.write(f'init:rest')
time.sleep(25)
specan.query('*opc?')

##########################
## begin gathering data ##
##########################
channels = [0, 19, 39]
phys = [1, 2, 3, 4]  # 1=LE1, 2=LE2, 3=LRS8, 4=LRS2

ch_dict = {
    0: 2402,
    19: 2440,
    39: 2480
}
ph_dict = {
    1: 'LE1M',
    2: 'LE2M',
    3: 'LRS8',
    4: 'LRS2'
}

print("Collecting Data...")

for x in channels:
    for y in phys:
        specan.write(f'freq:cent {ch_dict[x]} MHz')
        specan.query('*opc?')

        if y == 2:
            specan.write('freq:span 4 MHz')
            specan.query('*opc?')
        else:
            specan.write('freq:span 2 MHz')
            specan.query('*opc?')

        specan.write(f'init:rest')
        time.sleep(10)
        specan.query('*opc?')

        device.send_hci_command_by_name(
            "LE_Transmitter_Test_[v2]",
            TX_Channel=x,
            Length_of_Test_Data=255,
            Packet_Payload=0, PHY=y
        )
        print("Waiting for Response...")
        response = device.wait_for_event()
        print("Response Received: ")
        print(response)

        print(f'Current Test: {ch_dict[x]} - {ph_dict[y]}')

        time.sleep(90)
        if y == 3:
            time.sleep(90)

        specan.write('calc:mark1:max')
        specan.query('*opc?')
        time.sleep(1)

        specan.write(f'MMEM:STOR:SCR "{result_path}\\FCC OOB REF {ph_dict[y]} {ch_dict[x]}"')
        specan.query('*opc?')

        peak = specan.query('calc:mark1:y?')
        specan.query('*opc?')

        file.write(f'{ph_dict[y]} {ch_dict[x]}:\t{float(peak)}\t{float(peak) - 20}\n')

        device.send_hci_command_by_name(
            "LE_Test_End"
        )
        print("Waiting for Response...")
        response = device.wait_for_event()
        print("Response Received: ")
        print(response)

file.close()

session.close()
specan.close()