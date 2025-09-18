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
import argparse

##### SET DEFAULT PARAMETERS #####
### Parse optional parameters ###
parser = argparse.ArgumentParser()
parser.add_argument("-BLE", help="Performing power control only on BLE (currently not active). Usage: -BLE YES", type=str)
parser.add_argument("-TARGET", help="The target power for script to acheive, ignore units. Integer or decimal is acceptable. Usage: -TARGET 10", type=float)
args = parser.parse_args()

# Initialize script conditions/parameters 
if args.BLE: # Sets BLE testing condition
    BLE = True
else: 
    BLE = False

if args.TARGET: # Checks if TARGET OP is inputted, if not, then script only returns the max output power. 
    TARGET = args.TARGET
    EXCEL_NAME = 'DEFAULT' # Setting chip name for file
    EXCEL_NAME = input('Please input chip/board name for power tuning. \n') # Prompts user to input chip name for Excel output file 
    POWER_TUNING = True
else:
    POWER_TUNING = False


ENABLE_DUT_SCRIPT = 'C:\\Users\\LiuJe\\Documents\\Python_Scripts\\enable_dut.pl' # This should be manually set already on the lab PC, but can be manually found if necessary (Possible future update)
POKE_SCRIPT = "C:\\Users\\LiuJe\Documents\\Python_Scripts\\reg_poke.pl"
PEEK_SCRIPT = "C:\\Users\\LiuJe\Documents\\Python_Scripts\\reg_peek.pl"

### Script Functions ###
# Define a new function to find the nearest argument 
class PCON_Tuning: 
    def __init__(self):
        HEX = '0x0'
        OUTPUT_POWER = 10

        # Initialize instance variables
        self.hex = HEX
        self.power = OUTPUT_POWER 

    def find_nearest(self, power: float, search_array: pd.Series, hex_values: pd.Series):
        search_array = search_array.to_numpy()
        idx = (np.abs(search_array - power)).argmin()
        self.hex = hex_values[idx]
        self.power = search_array[idx]
        
        return self

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
            time.sleep(10)
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
    return power_values[1]

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
cbt = RsInstrument(GPIB_list[sig_idx][0])
cbt.write_str_with_opc("*RST")

connect_testmode(cbt)
# print(cbt.write_str_with_opc("PROC:PCON:STEP MAX"))
# print(cbt.query_str_list("ENH:PCON:STAT?")[0])

# Ensure DUT is at the max power
cbt.write_str_with_opc("PROC:PCON:STEP MAX")

if POWER_TUNING: 
    power_steps = [];

    while True: 
        power_state = cbt.query_str_list("ENH:PCON:STAT?")[0] 
        if "RMIN" in power_state:
            avg_op = convert_list(cbt.query_str_list("READ:POW:TIME?"))
            power_steps.append(avg_op)
            break
        else: 
            avg_op = convert_list(cbt.query_str_list("READ:POW:TIME?"))
            power_steps.append(avg_op)
            cbt.write_str_with_opc("PROC:PCON:STEP DOWN")


    # Pull all the hex values associated with the length of power_steps
    iteration = 0;
    DEFAULT_REGISTERS = ["0x600164", "0x600168", "0x60016C", "0x600170", "0x600174", "0x600178", "0x60017C", "0x600184"];
    reg_arr = DEFAULT_REGISTERS[:len(power_steps)]
    reg_peek = [];

    while iteration < len(power_steps):
        param = f'perl {PEEK_SCRIPT} {comport_list[0]} {reg_arr[iteration]}'
        pipe = subprocess.Popen(param, stdout=subprocess.PIPE)
        out, err = pipe.communicate()
        value = hex(int(out.decode()))
        reg_peek.append(value)
        iteration += 1

    # Zip together all the register addresses, register value, and corresponding output powers
    reg_peek = dict(zip(reg_arr, reg_peek))
    power_steps = dict(zip(reg_arr, power_steps))
    register_dict = {register: {"Hex Value":reg_peek[register], "Output Power": power_steps[register]} for register in reg_arr}

    # Compile all values int a Pandas DataFrame for better access performance
    DEFAULT_DF = pd.DataFrame.from_dict(register_dict)
    DEFAULT_DF = DEFAULT_DF.T
    DEFAULT_DF["Delta (Default)"] = DEFAULT_DF["Output Power"].diff()

    print("Default Power Table")
    print(DEFAULT_DF)

    # Adjust 0x600164 until it reaches the desired target output power
    DEFAULT_VAL = DEFAULT_DF.loc["0x600164"]["Hex Value"]
    DEFAULT_OP = DEFAULT_DF.loc["0x600168"]["Output Power"]
    temp_op = DEFAULT_DF.loc["0x600164"]["Output Power"]
    temp_val = int(DEFAULT_VAL, base=16)
    cbt.write_str_with_opc("PROC:PCON:STEP MAX")
    NEW_HEX = 0
    NEW_OP = 0

    print("Searching for optimal hex value to match target output power...")

    while True: 
        # Bring temp_op down to TARGET range
        while (temp_op > TARGET + 1):
            # To catch any temp_val conversions in case
            if type(temp_val) != int: 
                temp_val = int(temp_val, base=16)
            temp_val = hex(temp_val + 1) 
            temp_op = poke_read(POKE_SCRIPT, comport_list[0], reg_arr[0], temp_val)

        # Returns a DataFrame of potential candidates
        temp_df = pd.DataFrame()

        while (temp_op <= TARGET + 1) and (temp_op >= TARGET - 1):
            temp_candidate = {'Hex Value': temp_val, 'Output Power': temp_op}
            temp_df = temp_df.append(temp_candidate, ignore_index=True)
            if type(temp_val) != int: 
                temp_val = int(temp_val, base=16)
            temp_val = hex(temp_val + 1)
            temp_op = poke_read(POKE_SCRIPT, comport_list[0], reg_arr[0], temp_val)
            
        # Set output power back to its default value
        print(f'Target value reached. Returning max output power to default value.')
        poke_read(POKE_SCRIPT, comport_list[0], reg_arr[0], DEFAULT_VAL)

        # Finds value closest to TARGET 
        temp_df["Deviation"] = temp_df["Output Power"] - TARGET
        temp_df["Deviation"] = temp_df["Deviation"].abs()
        temp_idx = temp_df["Deviation"].idxmin()

        # Return the new value suggestion
        NEW_HEX = temp_df.iloc[temp_idx][0]
        NEW_OP = temp_df.iloc[temp_idx][1]
        print(f'New Hex Value: {NEW_HEX} \nNew Output Power: {NEW_OP}')

        # Create power table to use to optimize power control steps
        hex_step = hex(int(NEW_HEX))
        POWER_TABLE = pd.DataFrame(columns=['Hex Value', 'Output Power'])

        for step in range(len(power_steps)*4):
            hex_step = int(hex_step, base=16)
            hex_step += 1
            hex_step = hex(hex_step)
            output_power = poke_read(POKE_SCRIPT, comport_list[0], reg_arr[0], hex_step)
            step_row = pd.DataFrame([{'Hex Value':hex_step, 'Output Power':output_power}])
            POWER_TABLE = pd.concat([POWER_TABLE, step_row], axis=0, ignore_index=True)

        print(POWER_TABLE)

        # Initialize updated power control table with new values
        updated_Power_Table = pd.DataFrame(columns=['Register', 'New Hex Value', 'New Output Power'])
        updated_Power_Table['Register'] = reg_arr
        updated_Power_Table['New Hex Value'].iloc[0] = NEW_HEX
        updated_Power_Table['New Output Power'].iloc[0] = NEW_OP

        # Get desired output power array from new output power 
        steps = NEW_OP
        desired_Output_Power = []
        for i in range(len(reg_arr)-1):
            steps -= 3
            desired_Output_Power.append(steps)
        
        # Optimize power control steps
        idx = 1
        for power in desired_Output_Power: 
            result = PCON_Tuning()
            result = result.find_nearest(power, POWER_TABLE['Output Power'], POWER_TABLE['Hex Value'])
            updated_Power_Table['New Hex Value'].iloc[idx] = result.hex
            updated_Power_Table['New Output Power'].iloc[idx] = result.power
            idx += 1
        
        # Give delta values 
        updated_Power_Table['New Delta'] = updated_Power_Table['New Output Power'].diff()

        # Set 'Register' as index 
        updated_Power_Table.set_index('Register', inplace=True)

        # Return all CGS values to their default values
        print(f'Returning all register values to the default CGS values.')
        for register in reg_arr: 
            poke_read(POKE_SCRIPT, comport_list[0], register, DEFAULT_DF.loc[register]["Hex Value"])
        print(f'Default values restored.')

        OUTPUT_DF = DEFAULT_DF.join(updated_Power_Table)
        OUTPUT_DF.to_excel(f'{EXCEL_NAME}.xlsx')
        print(OUTPUT_DF)
        break
else: 
    avg_op = convert_list(cbt.query_str_list("READ:POW:TIME?"))
    param = f'perl {PEEK_SCRIPT} {comport_list[0]} 0x600164'
    pipe = subprocess.Popen(param, stdout=subprocess.PIPE)
    out, err = pipe.communicate()
    value = hex(int(out.decode()))
    print(f'Output power at 0x600164 is {avg_op} with hex value {value}. Run script again with \'-TARGET\' parameter if you want to perform power tuning.')