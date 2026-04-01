"""
Module Name: airoc_init
Description: functions related to initalizing AIROC devices
"""

import sys
from subprocess import run
from subprocess import Popen
import time
from unittest import result
sys.path.append("C:\\Users\\irvinelabuser\\Infineon\\Tools\\AIROC-Bluetooth-Test-and-Debug-Tool\\1.5.0.3898\\clients\\python\\src")
from infineon.airocbluetoothtool.client import client
from infineon.airocbluetoothtool.service import DEVICE_TYPE_UART

def initialize_airoc(com_port, baudrate):
    """Opens AIROC python server, initializes AIROC device, tests reset

    Args:
        com_port: (string) COM port of the AIROC device

    Returns:
        device: Device object for sending commands
        session: Session object to close later
    """
    Popen(["C:\\Users\\irvinelabuser\\Infineon\\Tools\\AIROC-Bluetooth-Test-and-Debug-Tool\\1.5.0.3898\\airocbluetoothtoolserver.exe"])
    time.sleep(3)

    session = client.connect('localhost', 1234)
    print("Connected!")

    device = session.open_device(com_port, DEVICE_TYPE_UART, baudrate)
    print("COM port opened!")

    print("Sending HCI reset...")
    device.send_hci_command_by_name('Reset')
    print("Waiting for response...")
    response = device.wait_for_event()
    print("Response received: ")
    print(response)

    return device, session

def enable_epa(device):
    """Enables ePA control for 829-based devices
    
    Args:
        device: Device object returned from initialize_airoc()

    Returns:
        None
    """
    print("Enable ePA")
    
    print("Routing TXEN")
    device.send_hci_command_by_name(
        'MCU_HCI_App_Cmd',
        Data="50 01 04 1A 06"
    )
    print("Waiting for response...")
    response = device.wait_for_event()
    print("Response received: ")
    print(response)

    print("Routing RXEN")
    device.send_hci_command_by_name(
        'MCU_HCI_App_Cmd',
        Data="50 01 05 1A 06"
    )
    print("Waiting for response...")
    response = device.wait_for_event()
    print("Response received: ")
    print(response)

    return

def download_fw_829(com_port, fw_path):
    """
    Downloads RFFW onto 829 devices
    
    :param com_port: COM port of AIROC device
    :param fw_path: Path to FW
    """
    print("Downloading FW...")

    result = run([r"C:\Users\irvinelabuser\Documents\playground\device_initialization\FW_download_892B0.bat", com_port, fw_path], capture_output=True, text=True, shell=True)
    print(result.stdout)

    if result.stderr:
        print(result.stderr)

    return

def download_fw_atomic2(com_port, baud_rate, fw_path):
    """
    Downloads RFFW onto Atomic-2 devices

    Args:
        com_port: COM port of Atomic-2 device
        baud_rate: baud rate of Atomic-2 device
        fw_path: path to FW file

    Returns:
        None
    """
    run(["perl", r"C:\Users\irvinelabuser\Documents\playground\device_initialization\FW_download_atomic2.pl", com_port, f"{baud_rate}", fw_path], shell=True)

    return

def launch_ram_atomic2(device):
    """
    Launches RAM to activate stored FW
    
    Args:
        com_port: COM port of Atomic-2 device
        baud_rate: baud rate of Atomic-2 device
        
    Returns:
        None
    """
    device.send_hci_command_by_name(
        "Launch_RAM",
        Address=0xFFFFFFFF,
        )
    print("Waiting for Response...")
    response = device.wait_for_event()
    print('Response Received: ')
    print(response)

    return

def provision_829B0():
    """
    Provisions 829B0 devices from NORMAL to NORMAL_NO_SECURE
    """
    print("Provisioning to NORMAL_NO_SECURE")

    run([r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe", "--login", r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/provision_829B0.sh"])

    return

def check_provisioning_829B1():
    """
    Checks the life cycle of the connected 829B1 device
    """
    print("Acquiring...")

    result = run(
                    [
                        r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe",
                        "--login",
                        r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup/other_scripts/acquire.sh"
                    ],
                    capture_output=True,
                    text=True,
                )

    provisioning = result.stdout.splitlines()
    for line in provisioning:
        if "NORMAL_NO_SECURE" in line:
            print("Device is NORMAL_NO_SECURE LCS!")
            return "NORMAL_NO_SECURE"
        elif "NORMAL" in line:
            print("Device is NORMAL LCS!")
            return "NORMAL"
        elif "SORT" in line:
            print("Device is SORT LCS!")
            return "SORT"
        elif "VIRGIN" in line:
            print("Device is VIRGIN LCS!")
            return "VIRGIN"
    return 1

def provision_829B1(final_state="NORMAL_NO_SECURE"):
    """
    Provisions the connected 829B1 device from init_state to final_state
    
    :param init_state: current state of the device
    :param final_state: desired state of the device
    """
    print("Checking LCS of device...")

    init_state = check_provisioning_829B1()

    print(f"Provisioning from {init_state} to {final_state}...")

    match init_state:
        case "VIRGIN":
            match final_state:
                case "SORT":
                    print("Cannot do SORT provisioning with this function")
                    return 1
                case "NORMAL":
                    run(
                        [
                            r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe",
                            "--login",
                            r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup/other_scripts/virgin_to_normal.sh"
                        ]
                    )
                    return 0
                case "NORMAL_NO_SECURE":
                    run(
                        [
                            r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe",
                            "--login",
                            r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup/other_scripts/virgin_to_normal.sh"
                        ]
                    )
                    run(
                        [
                            r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe",
                            "--login",
                            r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup/other_scripts/normal_to_normal_no_secure.sh"
                        ]
                    )
                    return 0
        case "SORT":
            match final_state:
                case "NORMAL":
                    run(
                        [
                            r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe",
                            "--login",
                            r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup/other_scripts/sort_to_normal_only_mode.sh"
                        ]
                    )
                    return 0
                case "NORMAL_NO_SECURE":
                    run(
                        [
                            r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe",
                            "--login",
                            r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup/other_scripts/sort_to_normal_no_secure.sh"
                        ]
                    )
                    return 0
        case "NORMAL":
            run(
                [
                    r"C:\Users\irvinelabuser\ModusToolbox\tools_3.7\modus-shell\bin\bash.exe",
                    "--login",
                    r"/cygdrive/c/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup/other_scripts/normal_to_normal_no_secure.sh"
                ]
            )
            return 0
    return 1

