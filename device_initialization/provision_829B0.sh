#!/bin/bash

orig_dir=$(pwd)

cd "C:\Users\irvinelabuser\mtw_refresh\Bluetooth_LE_Findme"

make device_transition DEVICE_MODE=normal-non-secure

cd "${orig_dir}"