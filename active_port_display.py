import os
import serial.tools.list_ports
import subprocess
import time

ports = serial.tools.list_ports.comports()

# Find Perl script file 
def find_script(file: str, search_path: str, application_check):
    script_location = [];

    for root, dir, files in os.walk(search_path):
        if application_check == 1:
            if file in dir: 
                script_location.append(os.path.join(root, file))
                break
        else: 
            if file in files: 
                script_location.append(os.path.join(root, file))
                break

    if len(script_location) == 0: 
        raise Exception(f"Unable to locate {file}. in {search_path}")
    
    return script_location

# Check for which COM port to use and return array of active ports
def check_ports(ports, script_location):
    active_ports = [];
    
    for port in ports: 
        if  'COM' in port.name:
            port_name = port.name.lower() + '@115200'
            pipe = subprocess.Popen(['perl', script_location, port_name], stdout=subprocess.PIPE)
            result = pipe.stdout.read()
            if 'Success' in result.decode('ascii'):
                active_ports.append(port_name)
                # print(result.decode('ascii'))
            else: 
                pass
        else: 
            pass
    return active_ports

# Function to enable "Device Under Test Mode" on BlueTool
def enable_dut(active_port, script_name): 
    pipe = subprocess.Popen(['perl', script_name, active_port], stdout=subprocess.PIPE)
    result = pipe.stdout.read()
    print(result)

def return_port(): 
    port_list = check_ports(ports, find_script('comport_check.pl', 'C:\\Users\\', 0)[0])
    attempts = 1
    
    while True: 
        if (len(port_list) == 0) & (attempts <= 3):
            attempts += 1
            # print(f"Retrying for active ports, attempt {attempts}")
            port_list = check_ports(ports, find_script('comport_check.pl', 'C:\\Users\\', 0)[0])
        else: 
            if (len(port_list) == 0) & (attempts > 3): 
                raise Exception(f"Unable to find active COM port(s) after {attempts} attempts. Please check connections.")
            break

    return port_list


# for port in port_list:
#     enable_dut(port, find_script('enable_dut.pl', 'C:\\Users\\', 0)[0])
# 
# print('Device Under Test Mode')

# Enabling DUT for Testing Connection 
