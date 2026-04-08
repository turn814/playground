"""
Module Name: utils
Description: utility functions related to AIROC devices
"""

# import sys
import serial.tools.list_ports
# from subprocess import run
# from subprocess import Popen
# sys.path.append("C:\\Users\\irvinelabuser\\Infineon\\Tools\\AIROC-Bluetooth-Test-and-Debug-Tool\\1.5.0.3898\\clients\\python\\src")
# from infineon.airocbluetoothtool.client import client
# from infineon.airocbluetoothtool.service import DEVICE_TYPE_UART

def com_finder(exp=1):
    """
    Finds and returns KitProg3 COM ports

    Args:
        exp: expected number of COM ports (1 for one, any number > 1 for multiple)
    
    Returns:
        com_port/com_ports: the COM port(s) in comXXX format
        1: in case of no COM ports found
    """
    ports = serial.tools.list_ports.comports()
    kp_ports = [p for p in ports if "kitprog" in p.description.lower()]

    if kp_ports:
        if exp == 1:
            if len(kp_ports) == 1:
                return f"{kp_ports[0]}".split()[0]
            elif len(kp_ports) > 1:
                print("Found multiple KitProg devices, please choose from below:\n")
                for p in kp_ports:
                    print(f"{p.device}: {p.description}")
                    com_port = input("Input COM port in COMxxx format:\n")
                return com_port
        elif exp > 1:
            print(f"Found {len(kp_ports)} KitProg devices")
            if len(kp_ports) != exp:
                print(f"COM port mismatch!\nExpected: {exp}, Found: {len(kp_ports)}")
                return 1
            com_ports = []
            for p in kp_ports:
                com_ports.append(f"{p}".split()[0])
            return com_ports

    else:
        print("Found no connected KitProg devices...")
        return 1
    
