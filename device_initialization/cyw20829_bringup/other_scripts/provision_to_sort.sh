#!/bin/bash

export OPENOCD="C:/Infineon/Tools/ModusToolboxProgtools-1.5/openocd"
export CYW20829_BRINGUP="C:/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup"

# Target type name
TARGET_TYPE=${1:-"si"}

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# Set variables to run provisioning
OPENOCD_PATH="$OPENOCD/bin/openocd"
OPENOCD_SCRIPT_PATH="$OPENOCD/scripts"
TO_SORT_PATH="set app_folder cyapp_to_sort/cyw20829/${TARGET_TYPE}"
TCL_SCRIPT_PATH="${CYW20829_BRINGUP}/executor.tcl"

printf "Launching to SORT:\n"
printf "===================\n"
echo_run "$OPENOCD_PATH" -s "$OPENOCD_SCRIPT_PATH" -c "$TO_SORT_PATH" -f "$TCL_SCRIPT_PATH"
