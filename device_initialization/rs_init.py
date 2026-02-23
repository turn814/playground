"""
Module Name: rs_init
Description: functions related to initalizing Rohde & Schwarz devices
"""

from RsInstrument import *
import time
import sys

def initialize_cbt(gpib_addr):
    cbt = RsInstrument(f"{gpib_addr}")
    print(cbt.query_str('*IDN?'))

    cbt.write_str('syst:rem:addr:sec 3, "BLUETOOTH_LE"')
    cbt.query_opc()

    cbt_ble = RsInstrument("GPIB::20::3::INSTR")
    print(cbt.query_str('syst:rem:addr:sec? 3'))

    cbt_ble.reset()
    cbt_ble.query_opc()
    return cbt_ble

