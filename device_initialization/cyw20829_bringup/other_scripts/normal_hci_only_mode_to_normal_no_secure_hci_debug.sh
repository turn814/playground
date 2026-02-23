#!/bin/bash

export OPENOCD="C:/Infineon/Tools/ModusToolboxProgtools-1.5/openocd"
export CYW20829_BRINGUP="C:/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup"

# Target type name
TARGET_TYPE=${1:-"si"}

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# Set variables to run provisioning
OPENOCD_PATH="$OPENOCD/bin/openocd"
OPENOCD_SCRIPT_PATH="$OPENOCD/scripts"
CFG_OEM_NORMAL_NO_SECURE="set config_file config_no_secure.conf"

PROV_OEM_PATH="set app_folder ${CYW20829_BRINGUP}
/cyapp_hci_debug/cyw20829/${TARGET_TYPE}"
TCL_SCRIPT_PATH="${CYW20829_BRINGUP}/executor.tcl"

printf "Launching provision OEM (NORMAL_NO_SECURE HCI DEBUG):\n"
printf "===================\n"
echo_run "$OPENOCD_PATH" -s "$OPENOCD_SCRIPT_PATH" -c "$CFG_OEM_NORMAL_NO_SECURE" -c "$PROV_OEM_PATH" -f "$TCL_SCRIPT_PATH"
