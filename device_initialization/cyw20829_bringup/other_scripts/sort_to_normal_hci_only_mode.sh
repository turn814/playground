#!/bin/bash

export OPENOCD="C:/Infineon/Tools/ModusToolboxProgtools-1.5/openocd"
export CYW20829_BRINGUP="C:/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup"

# Target type name
TARGET_TYPE=${1:-"si"}

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# Set variables to run provisioning
OPENOCD_PATH="$OPENOCD/bin/openocd"
OPENOCD_SCRIPT_PATH="$OPENOCD/scripts"
CFG_ICV_NORMAL="set config_file config_hci_mode_wounded.conf"

PROV_ICV_PATH="set app_folder ${CYW20829_BRINGUP}
/cyapp_prov_icv/cyw20829/${TARGET_TYPE}"
TCL_SCRIPT_PATH="${CYW20829_BRINGUP}/executor.tcl"

printf "Launching provision ICV (NORMAL):\n"
printf "===================\n"
echo_run "$OPENOCD_PATH" -s "$OPENOCD_SCRIPT_PATH" -c "$CFG_ICV_NORMAL" -c "$PROV_ICV_PATH" -f "$TCL_SCRIPT_PATH"
