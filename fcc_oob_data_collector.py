import sys
sys.path.append("C:\\Users\\irvinelabuser\\Infineon\\Tools\\AIROC-Bluetooth-Test-and-Debug-Tool\\1.3.0.3116\\clients\\python\\src") # check this path before running

from infineon.airocbluetoothtool.client import client
from infineon.airocbluetoothtool.service import DEVICE_TYPE_UART

import pyvisa
import time
import csv

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

############################
## initialize flash drive ##
############################
print("Please insert flash drive and wait for any drivers to install")
pauser = input("Press enter to continue...")

print("Please input the path of the directory in which you would like your results to be saved")
print("Use the full path name! (ex. F:\\\\...)")
result_path = input("Path: ")

###################################################
## initialize specan for emissions measurements ##
###################################################
print ("Please input the appropriate offset for your specan")
print("Currently: Rack Specan = 11.7 dB; Cart Specan = ??")
print("Use the following format: 11.7 dB")
offset = input("Offset: ")

rm = pyvisa.ResourceManager()
inst_list = rm.list_resources()
print(inst_list)
print ("Please select your instrument by copying it's address below")
print("Rack Specan Agilent ID = MY49431636; Cart Specan Agilent ID = MY56005689")
instr = input("Instrument address here: ")
specan = rm.open_resource(instr)
print(specan.query('*IDN?'))
specan.query('*opc?')

specan.write('*rst')
specan.query('*opc?')

print("Setting up specan for emissions measurements...")

# set attenuation level
specan.write('pow:att 18')
specan.write('*opc?')
specan.write('disp:wind:trac:y:rlev 20 dBm')
time.sleep(5)
specan.write('*opc?') # query is interrupted for some reason

# offset
specan.write(f'disp:wind:trac:y:rlev:offs {offset}')
specan.query('*opc?')

# frequency 30 MHz to 26.5 GHz
specan.write('freq:star 30 MHz')
specan.query('*opc?')
specan.write('freq:stop 26.5 GHz')
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

# sweep points 26471
specan.write('swe:poin 26471')
specan.query('*opc?')

# set to continuous measurement
specan.write('init:cont on')
specan.query('*opc?')

# turn on peak table
specan.write('calc:mark:peak:tabl:stat 1')
specan.query('*opc?')

# restart
specan.write(f'init:rest')
time.sleep(25)
specan.query('*opc?')

######################
## read limits file ##
######################
f = open("Reference Measurements and 20 dBc Limits.txt", "r", encoding="utf8")
f_reader = csv.DictReader(f, delimiter="\t")
limits = []
for value in f_reader:
    limit = value["20 dBc limit"]
    limits.append(limit)
f.close()

limit_iterator = 0

######################################################
## begin gathering data for emissions measurements ##
######################################################
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

print("Starting data collection for emissions measurements...")

for x in channels:
    for y in phys:
        specan.write(f'init:rest')
        time.sleep(25)
        specan.query('*opc?')

        specan.write(f'disp:wind:trac:y:dlin {limits[limit_iterator]} dBm')
        specan.query('*opc?')
        limit_iterator += 1

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

        print(f"Current Test: {ph_dict[y]} - {ch_dict[x]} emissions")

        time.sleep(60)

        specan.write('calc:mark1:max')
        specan.query('*opc?')
        time.sleep(1)

        specan.write(f'MMEM:STOR:SCR "{result_path}\\FCC OOB EMI {ph_dict[y]} {ch_dict[x]}"')
        specan.query('*opc?')

        device.send_hci_command_by_name(
            "LE_Test_End"
        )
        print("Waiting for Response...")
        response = device.wait_for_event()
        print("Response Received: ")
        print(response)

##############################################
## set up specan for zoomed in measurements ##
##############################################
specan.write('*cls')
specan.query('*opc?')

print("Setting up specan for zoomed in measurements...")

# frequency 2310 MHz to 2410 MHz
specan.write('freq:star 2310 MHz')
specan.query('*opc?')
specan.write('freq:stop 2410 MHz')
specan.query('*opc?')

# sweep points 2001
specan.write('swe:poin 2001')
specan.query('*opc?')

# marker 2 on
specan.write('calc:mark2:mode pos')
specan.query('*opc?')

# lines on for marker 2
specan.write('calc:mark2:lin on')
specan.query('*opc?')

# restart
specan.write(f'init:rest')
time.sleep(25)
specan.query('*opc?')

#####################################################
## begin gathering data for zoomed in measurements ##
#####################################################
channels_zoom = [0, 39]

ch_dict_zoom = {
    0: 2402,
    39: 2480
}

limit_iterator = 0

for x in channels_zoom:
    if x == 0:
        specan.write('freq:star 2310 MHz')
        specan.query('*opc?')
        specan.write('freq:stop 2410 MHz')
        specan.query('*opc?')
        specan.write('calc:mark2:mode pos')
        specan.query('*opc?')
        specan.write('calc:mark2:x 2400 MHz')
        specan.query('*opc?')
    else:
        specan.write('freq:star 2472 MHz')
        specan.query('*opc?')
        specan.write('freq:stop 2500 MHz')
        specan.query('*opc?')
        specan.write('calc:mark2:mode pos')
        specan.query('*opc?')
        specan.write('calc:mark2:x 2483.5 MHz')
        specan.query('*opc?')
    
    for y in phys:
        specan.write(f'init:rest')
        time.sleep(25)
        specan.query('*opc?')

        specan.write(f'disp:wind:trac:y:dlin {limits[limit_iterator]} dBm')
        specan.query('*opc?')
        limit_iterator += 1

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

        print(f"Current Test: {ph_dict[y]} - {ch_dict[x]} zoom")

        time.sleep(60)

        specan.write('calc:mark1:max')
        specan.query('*opc?')
        time.sleep(1)

        specan.write(f'MMEM:STOR:SCR "{result_path}\\FCC OOB ZOOM {ph_dict[y]} {ch_dict[x]}"')
        specan.query('*opc?')

        device.send_hci_command_by_name(
            "LE_Test_End"
        )
        print("Waiting for Response...")
        response = device.wait_for_event()
        print("Response Received: ")
        print(response)

session.close()
specan.close()