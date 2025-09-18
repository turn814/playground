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
# print("Please ensure that airocbluetoothtoolserver.exe is running!")
# pauser = input("Press enter to continue...")

# print ("Please enter the COM port number of your device in the following format")
# port = input("COM#\n")
port = "COM91"

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

# send READ_BD_ADDR
device.send_hci_command_by_name('Read_BD_ADDR')
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

# send MCU_HCI_App_Cmd
device.send_hci_command_by_name(
    'MCU_HCI_App_Cmd',
    Data='50 01 04 1A 06'
    )
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

device.send_hci_command_by_name(
    'MCU_HCI_App_Cmd',
    Data='50 01 05 1A 06'
    )
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

device.send_hci_command_by_name(
    'LE_Transmitter_Test_[v1]',
    TX_Channel='19'
    )
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

pauser = input("Transmitting... Press Enter to continue...")

device.send_hci_command_by_name('LE_Test_End')
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

device.send_hci_command_by_name('LE_Receiver_Test_[v1]')
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

pauser = input("Receiving... Press Enter to continue...")

device.send_hci_command_by_name('LE_Test_End')
print("Waiting for Response...")
response = device.wait_for_event()
print('Response Received: ')
print(response)

session.close()