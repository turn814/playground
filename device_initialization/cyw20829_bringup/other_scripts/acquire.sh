#!/bin/bash

export OPENOCD="C:/Infineon/Tools/ModusToolboxProgtools-1.5/openocd"
export CYW20829_BRINGUP="C:/Users/irvinelabuser/Documents/playground/device_initialization/cyw20829_bringup"

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# Set variables to run acquire
OPENOCD_PATH="$OPENOCD/bin/openocd"
OPENOCD_SCRIPT_PATH="$OPENOCD/scripts"
TCL_SCRIPT_PATH="${CYW20829_BRINGUP}/acquire.tcl"

echo_run "$OPENOCD_PATH" -s "$OPENOCD_SCRIPT_PATH" -f "$TCL_SCRIPT_PATH"
