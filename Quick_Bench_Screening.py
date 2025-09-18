#Package dependencies
from unicodedata import decimal
from RsInstrument import *
import numpy as np 
import time
import subprocess
import active_port_display
import warnings 
import os
warnings.simplefilter(action='ignore', category=FutureWarning)

import pandas as pd 

ENABLE_DUT_SCRIPT = 'C:\\Users\\LiuJe\\Documents\\Python_Scripts\\enable_dut.pl'
### Script Functions ###
# Check for specifically CBT instrument (if multiple R&S instruments are found)
def check_CBT(instrument): 
    cbt = RsInstrument(instrument)
    return(cbt.query_str("*IDN?"))

# Connect testmode via CBT (missing BlueTool commands, will need to do that manually still)
def connect_testmode(cbt):
    attempts = 1
    cbt.write_str_with_opc("*RST")
    cbt.write_str_with_opc("*WAI")
    standby_check = cbt.query_str("SIGN:XST?")
    if "SBY" in standby_check:
        print(f"Looking for DUT: Attempt {attempts}")  
        while attempts <= 3:
            attempts += 1
            cbt.write_str("PROC:SIGN:ACT INQ")
            cbt.write_str_with_opc("*WAI")
            time.sleep(5)
            cbt.write_str_with_opc("PROC:SIGN:ACT SINQ")
            bd_addr_list = np.array(cbt.query_str_list("FETC:SIGN:PTAR?"))
            bd_found = np.where(bd_addr_list == "BD01")
            if len(bd_found[0]) != 0: 
                print(f"BD address found: {bd_addr_list[bd_found[0] + 1][0]}")
                cbt.write_str_with_opc(f"CONF:SIGN:PTAR {bd_addr_list[bd_found[0]][0]}")
                print(f"Connecting to DUT...")
                cbt.write_str_with_opc("PROC:SIGN:ACT TEST")
                time.sleep(1)
                if "TEST" in cbt.query_str("SIGN:XST?"):
                    print(f"DUT connected in testmode.")
                    break
                else: 
                    continue
            else: 
                if attempts == 3 and len(bd_found[0]) == 0:
                    print(f"Unable to find DUT after {attempts} attempts, please check connection settings.")
                    cbt.write_str_with_opc("*RST")
                    break
                else: 
                    print(f"Looking for DUT: Attempt {attempts}")

# Check for output power average output power 
def convert_list(power_values):
    power_values = np.asarray(power_values, dtype=float)
    power_values = np.around(power_values, decimals=2)
    return power_values

# Update hex value and check for output power
def poke_read(POKE_SCRIPT, comport, register_addr, hex_value):
    param = f'perl {POKE_SCRIPT} {comport} {register_addr} {hex_value}'
    subprocess.Popen(param, stdout=subprocess.PIPE)
    time.sleep(1)
    return convert_list(cbt.query_str_list("READ:POW:TIME?"))

# Find script function
def find_script(file: str, search_path: str, application_check):
    script_location = 'DEFAULT';

    for root, dir, files in os.walk(search_path):
        if application_check == 1:
            if file in dir: 
                temp_str = os.path.join(root, file)
                script_location = temp_str
                break
        else: 
            if file in files: 
                temp_str = os.path.join(root, file)
                script_location = temp_str
                break

    if len(script_location) == 0: 
        raise Exception(f"Unable to locate {file} in {search_path}")
    
    return script_location

### Start of power control script ###
## Init GPIB Connection ##
# Check for all Rohde & Schwarz instruments using the NI GPIB connection
try: 
    instr_list = RsInstrument.list_resources("?*", "ni")
except: 
    raise Exception(f"No GPIB connection detected.")
# print(instr_list)

# Gather devices into a single GPIB list
GPIB_list = [];
device_filter = ["GPIB", "INSTR"];

[GPIB_list.append(device) for device in instr_list if all(filter_value in device for filter_value in device_filter)]
#print(GPIB_list)

# Find which COM port to perform power control from 
comport_list = active_port_display.return_port()
print(f'COMPORT(S) available are: {comport_list}')

# Enable device under testmode via Perl script
print('Enabling device under testmode via BlueTool...')
subprocess.Popen(['perl', f'{ENABLE_DUT_SCRIPT}', comport_list[0]], stdout=subprocess.PIPE)

# Checking if BLUETOOTH Signalling Module is installed on CBT
GPIB_list = np.array(GPIB_list)
cbt = RsInstrument(GPIB_list[0])
modules = cbt.query_str_list("SYST:REM:ADDR:SEC?")
modules = np.array(modules)
sig_idx = np.where(modules == "BLUETOOTH_Sig")
#rf_idx = np.where(modules == "RF_NSig")
#cbt = RsInstrument(GPIB_list[rf_idx][0])
# Set input and output attenuation
#cbt.write_str("SENS:CORR:LOSS:MAG 0.6")
#cbt.write_str("SOUR:CORR:LOSS:MAG 0.6")
cbt = RsInstrument(GPIB_list[sig_idx][0])
cbt.write_str_with_opc("*RST")
connect_testmode(cbt)

# Read output power
avg_op = convert_list(cbt.query_str_list("READ:POW:TIME?"))
print(f'Avg. OP: {avg_op[1]}')
time.sleep(1)
cbt.write_str_with_opc("*RST")

# Read deviation accuracy
cbt.write_str("CONF:SSIG:TMOD:TXT:PATT P11")
time.sleep(1)
cbt.write_str("CONF:SSIG:TMOD:TXT:PTYP DH5")
time.sleep(1)
cbt.write_str("INIT:MOD:DEV")
time.sleep(1)
avg_accuracy = convert_list(cbt.query_str_list("READ:SCAL:MOD:DEV?"))
print(f'Avg. Freq. Accuracy: {avg_accuracy[1]}')
print(f'Avg. Freq. Deviation: {avg_accuracy[13]}')
cbt.write_str_with_opc("*RST")

# Read DEVM
cbt.write_str("CONF:SSIG:TMOD:TXT:PATT SPRS")
time.sleep(1)
cbt.write_str("CONF:SSIG:TMOD:TXT:PTYP E35P")
time.sleep(1)
cbt.write_str("INIT:MOD:DPSK")
time.sleep(1)
avg_devm = convert_list(cbt.query_str_list("READ:SCAL:MOD:DPSK?"))
print(avg_devm)
cbt.write_str_with_opc("*RST")

# RX Sensitivity
cbt.write_str("INIT:RXQ:BER")
time.sleep(1)
avg_ber = convert_list(cbt.query_str_list("READ:SCAL:RXQ:BER?"))
print(f'Avg. BER: {avg_ber[1]}')

