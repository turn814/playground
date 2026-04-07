"""
Module Name: LE_RF_testing
Description: functions related to testing the radio on AIROC devices
"""

from RsInstrument import *
import sys
from subprocess import run
from subprocess import Popen
import csv
import time
sys.path.append("C:\\Users\\irvinelabuser\\Infineon\\Tools\\AIROC-Bluetooth-Test-and-Debug-Tool\\1.5.0.3898\\clients\\python\\src")
from infineon.airocbluetoothtool.client import client
from infineon.airocbluetoothtool.service import DEVICE_TYPE_UART

def LE_OP_test(DUT, cbt_ble, channels, output_file, cal_file=r"C:\Users\irvinelabuser\Documents\playground\device_testing\cal_file_isaac_bench.csv"):
    """Initiates and measures output power of LE_Transmitter_Test on each specified channel

    Args:
        DUT: device object returned from initialize_airoc()
        cbt_ble: cbt object returned from initialize_cbt()
        channels: list of channels to be tested (ex. [0, 19, 39])
        output_file: opened file object to log measurement results
        cal_file: formatted list of path losses for each channel

    Returns:
        None
    """
    cbt_ble.write_str_with_opc("conf:euts:freq:unit mhz")
    cbt_ble.write_str_with_opc("conf:euts:patt oth")

    f = open(cal_file, mode='r')
    reader = csv.DictReader(f)
    cal_data = next(reader)

    output_file.write("\n***Output Power Test***\n")
    output_file.write("Channel,Output Power (dBm)\n")

    DUT.send_hci_command_by_name(
        "LE_Transmitter_Test_[v1]",
        TX_Channel=19,
        Length_of_Test_Data=37,
        Packet_Payload="Pseudo-Random bit sequence 9"
    )
    print("Waiting for response...")
    response = DUT.wait_for_event()
    print("Response Received: ")
    print(response)

    print("Warming up radio...")
    time.sleep(5)

    DUT.send_hci_command_by_name("LE_Test_End")
    print("Waiting for Response...")
    response = DUT.wait_for_event()
    print('Response Received: ')
    print(response)

    for c in channels:
        loss = float(cal_data[f"{c}"])

        DUT.send_hci_command_by_name(
            "LE_Transmitter_Test_[v1]",
            TX_Channel=c,
            Length_of_Test_Data=37,
            Packet_Payload="Pseudo-Random bit sequence 9"
            )
        print("Waiting for Response...")
        response = DUT.wait_for_event()
        print('Response Received: ')
        print(response)
        
        ch_arg = f"conf:euts:freq 2{402+(c*2)}"
        cbt_ble.write_str(ch_arg)
        cbt_ble.query_opc()

        time.sleep(1)
        
        power_arr_str = cbt_ble.query_str("read:pow:time?").split(",")
        cbt_ble.query_opc()
        power_arr = [float(item) for item in power_arr_str]
        power_avg = power_arr[1] + loss

        DUT.send_hci_command_by_name("LE_Test_End")
        print("Waiting for Response...")
        response = DUT.wait_for_event()
        print('Response Received: ')
        print(response)

        output_file.write(f"{2402+(c*2)},{power_avg}\n")

        print(f"{2402+(c*2)}: {power_avg} dBm")

    DUT.send_hci_command_by_name('Reset')
    print("Waiting for Response...")
    response = DUT.wait_for_event()
    print('Response Received: ')
    print(response)

    return

def LE_ICFT_test(DUT, cbt_ble, channels, output_file):
    """Initiates and measures frequency accuracy of LE_Transmitter_Test on each specified channel

    Args:
        DUT: device object returned from initialize_airoc()
        cbt_ble: cbt object returned from initialize_cbt()
        channels: list of channels to be tested (ex. 0, 19, 39)
        output_file: opened file object to log measurement results

    Returns:
        None
    """
    cbt_ble.write_str_with_opc("conf:euts:patt P11")

    output_file.write("\n***Frequency Accuracy (mod char) Test***\n")
    output_file.write("Channel,Frequency Accuracy (kHz)\n")

    DUT.send_hci_command_by_name(
        "LE_Transmitter_Test_[v1]",
        TX_Channel=19,
        Length_of_Test_Data=37,
        Packet_Payload="Pattern of alternating bits '10101010'"
    )
    print("Waiting for response...")
    response = DUT.wait_for_event()
    print("Response Received: ")
    print(response)

    print("Warming up radio...")
    time.sleep(5)

    DUT.send_hci_command_by_name("LE_Test_End")
    print("Waiting for Response...")
    response = DUT.wait_for_event()
    print('Response Received: ')
    print(response)

    for c in channels:
        DUT.send_hci_command_by_name(
            "LE_Transmitter_Test_[v1]",
            TX_Channel=c,
            Length_of_Test_Data=37,
            Packet_Payload="Pattern of alternating bits '10101010'"
            )
        print("Waiting for Response...")
        response = DUT.wait_for_event()
        print('Response Received: ')
        print(response)
        
        ch_arg = f"conf:euts:freq 2{402+(c*2)}"
        cbt_ble.write_str(ch_arg)
        cbt_ble.query_opc()

        time.sleep(1)
        
        freq_dev_arr_str = cbt_ble.query_str("read:mod:dev?").split(",")
        cbt_ble.query_opc()
        freq_dev_arr = [float(item) for item in freq_dev_arr_str]
        freq_acc_avg = freq_dev_arr[1]

        DUT.send_hci_command_by_name("LE_Test_End")
        print("Waiting for Response...")
        response = DUT.wait_for_event()
        print('Response Received: ')
        print(response)

        output_file.write(f"{2402+(c*2)},{freq_acc_avg}\n")

        print(f"{2402+(c*2)}: {freq_acc_avg} kHz")

    DUT.send_hci_command_by_name('Reset')
    print("Waiting for Response...")
    response = DUT.wait_for_event()
    print('Response Received: ')
    print(response)

    return

def LE_RX_sensitivity_sweep(DUT, cbt_ble, channels, output_file, start=-60, stop=-110, step=-1, small_step=-2, cal_file=r"C:\Users\irvinelabuser\Documents\playground\device_testing\cal_file_isaac_bench.csv"):
    """Initiates and measures receiver sensitivity on each specified channel

    Args:
        DUT: device object returned from initialize_airoc()
        cbt_ble: cbt object returned from initialize_cbt()
        channels: list of channels to be tested (ex. 0, 19, 39)
        output_file: opened file object to log measurement results
        start: starting TX level in dBm (included)
        stop: stopping TX level in dBm (excluded)
        step: TX level step size in dB
        small_step: more granular TX level step size in 0.1 dB (use 0 to skip granular measurements)
        cal_file: formatted list of path losses for each channel

    Returns:
        None
    """
    cbt_ble.write_str_with_opc("conf:euts:freq:unit mhz")

    f = open(cal_file, mode='r')
    reader = csv.DictReader(f)
    cal_data = next(reader)

    output_file.write("\n***Receiver Sensitivity Test***\n")
    output_file.write("Channel,TX Power (dBm),Number of Packets Received,PER\n")

    ch_unit_arg = f"conf:rxq:rqg:freq:unit MHZ"
    cbt_ble.write_str(ch_unit_arg)
    cbt_ble.query_opc()

    done = False

    for c in channels:
        loss = float(cal_data[f"{c}"])
        final_tx_power = start
        for r in range(start, stop, step):
            DUT.send_hci_command_by_name(
                "LE_Receiver_Test_[v1]",
                RX_Channel=c,
                )
            print("Waiting for Response...")
            response = DUT.wait_for_event()
            print('Response Received: ')
            print(response)

            ch_arg = f"conf:rxq:rqg:freq 2{402+(c*2)}"
            cbt_ble.write_str(ch_arg)
            cbt_ble.query_opc()

            tx_level_arg = f"conf:rxq:rqg:lev {r + loss}"
            cbt_ble.write_str(tx_level_arg)
            cbt_ble.query_opc()

            time.sleep(1)
        
            cbt_ble.query_str("read:rxq:per?")
            cbt_ble.query_opc()

            DUT.send_hci_command_by_name("LE_Test_End")
            print("Waiting for Response...")
            response = DUT.wait_for_event()
            num_packets = response.event_params['Num_Of_Packets_Received']            
            print('Response Received: ')
            print(response)

            final_tx_power = r - step

            output_file.write(f"{2402+(c*2)},{r},{num_packets},{(1500 - num_packets) / 1500 * 100}\n")

            print(f"{2402+(c*2)} at {r} dBm: {num_packets} packets - PER: {(1500 - num_packets) / 1500 * 100}")

            if num_packets <= 1038:
                if small_step == 0:
                    break
                r_10 = range((r+2)*10, r*10, small_step)
                r_1 = [x /10 for x in r_10]
                for i in r_1:
                    DUT.send_hci_command_by_name(
                        "LE_Receiver_Test_[v1]",
                        RX_Channel=c,
                        )
                    print("Waiting for Response...")
                    response = DUT.wait_for_event()
                    print('Response Received: ')
                    print(response)

                    ch_arg = f"conf:rxq:rqg:freq 2{402+(c*2)}"
                    cbt_ble.write_str(ch_arg)
                    cbt_ble.query_opc()

                    tx_level_arg = f"conf:rxq:rqg:lev {i + loss}"
                    cbt_ble.write_str(tx_level_arg)
                    cbt_ble.query_opc()

                    time.sleep(1)
                
                    cbt_ble.query_str("read:rxq:per?")
                    cbt_ble.query_opc()

                    DUT.send_hci_command_by_name("LE_Test_End")
                    print("Waiting for Response...")
                    response = DUT.wait_for_event()
                    num_packets = response.event_params['Num_Of_Packets_Received']
                    print('Response Received: ')
                    print(response)

                    final_tx_power = i - small_step/10

                    output_file.write(f"{2402+(c*2)},{i},{num_packets},{(1500 - num_packets) / 1500 * 100}\n")

                    print(f"{2402+(c*2)} at {i} dBm: {num_packets} packets - PER: {(1500 - num_packets) / 1500 * 100}")

                    if num_packets <= 1038:
                        done = True
                        break
                if done:
                    break
                else:
                    continue
        output_file.write(f"{2402 + (c*2)} FINAL: {final_tx_power}\n")
    
    return
