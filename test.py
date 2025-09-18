import sys

# import COM port from batch script
sys.path.append('./src')

#import airoc modules
from infineon.airocbluetoothtool.client import client
from infineon.airocbluetoothtool.service import DEVICE_TYPE_UART

import pyvisa

import numpy as np

print ("Please ensure that your instrument is connected to the PC")
pauser = input("Press enter to continue...")

rm = pyvisa.ResourceManager()
inst_list = rm.list_resources()
print(inst_list)
print ("Please select your instrument by copying it's address below")
instr = input("Instrument address here: ")
specan = rm.open_resource(instr)
print(specan.query('*IDN?'))
specan.query('*opc?')

specan.write('*rst')
specan.query('*opc?')

class settings_builder:
    def __init__(self, f_type='start_stop', f_start='30 MHz', f_end='12.75 GHz', f_center='2440 MHz', f_span='10 MHz',
                 rbw='1 MHz', vbw='3 MHz', trace='maxh', s_time_auto='on', s_pts='12721', trigger='imm', filt_type='gaussian', limit='41.2 dBm'):
        self.f_type = f_type
        self.f_start = f_start
        self.f_end = f_end
        self.f_center = f_center
        self.f_span = f_span
        self.rbw = rbw
        self.vbw = vbw
        self.trace = trace
        self.s_time_auto = s_time_auto
        self.s_pts = s_pts
        self.trigger = trigger
        self.filt_type = filt_type
        self.limit = limit
    
    def set(self):
        if self.f_type == 'center_span':
            specan.write(f'freq:center {self.f_center}')
            specan.query('*opc?')
            specan.write(f'freq:span {self.f_span}')
            specan.query('*opc?')
        elif self.f_type == 'start_stop':
            specan.write(f'freq:start {self.f_start}')
            specan.query('*opc?')
            specan.write(f'freq:stop {self.f_end}')
            specan.query('*opc?')
        else:
            print ("No valid frequency type selected!")
        # rbw
        specan.write(f'band {self.rbw}')
        specan.query('*opc?')
        # vbw
        specan.write(f'band:vid {self.vbw}')
        specan.query('*opc?')
        # trace
        specan.write(f'trac1:type {self.trace}')
        specan.query('*opc?')
        # detector
        specan.write(f'det:trac1:auto on')
        specan.query('*opc?')
        #trigger
        specan.write(f'trig:sour:{self.trigger}')
        specan.query('*opc?')
        specan.write(f'init:cont 1')
        specan.query('*opc?')
        # sweep time
        specan.write(f'swe:time:auto {self.s_time_auto}')
        specan.query('*opc?')
        # sweep points
        specan.write(f'swe:poin {self.s_pts}')
        specan.query('*opc?')
        #limit line
        specan.write(f'disp:wind:trac:y:dlin {self.limit}')
        specan.query('*opc?')
        #attenuation
        specan.write(f'pow:att 16')
        specan.query('*opc?')


#    def attenuate(self):
#        while specan.query('syst:err:over:state?')

specan.write('init:rest')

test = settings_builder()
test.set()

pauser = input("check if the settings are set!")

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

device.send_hci_command_by_name('LE_Transmitter_Test_[v1]', TX_Channel=19, Length_of_Test_Data=255, Packet_Payload=0)
print ("Waiting for Response...")
response = device.wait_for_event()
print ('Response Receieved: ')
print (response)

pauser = input("Press enter to continue...")

specan.write('MMEM:STOR:SCR "F:\\test.png"')
specan.query('*opc?')

device.send_hci_command_by_name('LE_Test_End')
print ("Waiting for Response...")
response = device.wait_for_event()
print ('Response Receieved: ')
print (response)

session.close()