#!/bin/bash

# Configure to run openocd from cygwin
OPENOCD_PATH_WIN="$OPENOCD"
OPENOCD_PATH=`cygpath -u $OPENOCD_PATH_WIN`

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# Folder with service application
SERV_APP=${1:-"cyapp_to_rma"}

# Service application descriptor address (defined in TOC2)
SERVICE_APP_DESCR_ADDR=${2:-8192}

################################ Functions #####################################

function hex_str_to_bin() {
  printf "\x${1:6:2}"
  printf "\x${1:4:2}"
  printf "\x${1:2:2}"
  printf "\x${1:0:2}"
}

####################### Check required files ###################################

if [[ "$SERV_APP" == "NONE" ]]; then
    FILE=${SERV_APP}/${SERV_APP}_signed.bin
    if [ ! -f "$FILE" ]; then
        echo "$FILE does not exist."
        exit
    fi

    FILE=${SERV_APP}/in_params.bin
    if [[ ! -f "$FILE" ]]; then
        echo "$FILE does not exist."
        exit
    fi
fi

###################### Generate SERVICE_APP_DESCR ##############################

SERVICE_APP_DESCR_SIZE=20
INPUT_PARAM_ADDR=`expr $SERVICE_APP_DESCR_ADDR + $SERVICE_APP_DESCR_SIZE`
INPUT_PARAM_SIZE=`wc -c ${SERV_APP}/in_params.bin | awk '{print $1}'`
INPUT_PARAM_SIZE_MAX=4096

SERVICE_APP_ADDR=`expr $INPUT_PARAM_ADDR + $INPUT_PARAM_SIZE_MAX`
SERVICE_APP_SIZE=`wc -c ${SERV_APP}/${SERV_APP}_signed.bin | awk '{print $1}'`

if [[ $INPUT_PARAM_SIZE -gt $INPUT_PARAM_SIZE_MAX ]]; then
    echo "Input parameters file is grater than $INPUT_PARAM_SIZE_MAX"
    exit
fi

# Remove existing file
`rm -f serv_app_descr.bin`

# Convert to hex string (without 0x prefix)
SERVICE_APP_DESCR_SIZE_HEX=$(printf "%08x" $SERVICE_APP_DESCR_SIZE)
SERVICE_APP_ADDR_HEX=$(printf "%08x" $SERVICE_APP_ADDR)
SERVICE_APP_SIZE_HEX=$(printf "%08x" $SERVICE_APP_SIZE)
INPUT_PARAM_ADDR_HEX=$(printf "%08x" $INPUT_PARAM_ADDR)
INPUT_PARAM_SIZE_HEX=$(printf "%08x" $INPUT_PARAM_SIZE)

# Write 4 bytes from hex string, LSB first
hex_str_to_bin $SERVICE_APP_DESCR_SIZE_HEX > serv_app_descr.bin
hex_str_to_bin $SERVICE_APP_ADDR_HEX >> serv_app_descr.bin
hex_str_to_bin $SERVICE_APP_SIZE_HEX >> serv_app_descr.bin
hex_str_to_bin $INPUT_PARAM_ADDR_HEX >> serv_app_descr.bin
hex_str_to_bin $INPUT_PARAM_SIZE_HEX >> serv_app_descr.bin

############## Program SERV_APP_DESCR, INPUT_PARAMS and SERVICE_APP ############

SERVICE_APP_DESCR_ADDR_PROG=$(printf "0x%x" $SERVICE_APP_DESCR_ADDR)
CMD0="set image_bin serv_app_descr.bin"
CMD1="set image_size $SERVICE_APP_DESCR_SIZE"
CMD2="set ext_flash_addr $SERVICE_APP_DESCR_ADDR_PROG"
CMD3="set encrypt 0"

# Program SERV_APP_DESCR object into the external memory
echo_run $OPENOCD_PATH/bin/openocd.exe -s $OPENOCD_PATH_WIN/scripts -c "$CMD0; $CMD1; $CMD2; $CMD3" -f cyapp_flash_loader.tcl

INPUT_PARAM_ADDR_PROG=$(printf "0x%x" $INPUT_PARAM_ADDR)
CMD0="set image_bin ${SERV_APP}/in_params.bin"
CMD1="set image_size $INPUT_PARAM_SIZE"
CMD2="set ext_flash_addr $INPUT_PARAM_ADDR_PROG"
CMD3="set encrypt 0"

# Program SERV_APP INPUT PARAMETERS into the external memory
echo_run $OPENOCD_PATH/bin/openocd.exe -s $OPENOCD_PATH_WIN/scripts -c "$CMD0; $CMD1; $CMD2; $CMD3" -f cyapp_flash_loader.tcl

SERVICE_APP_ADDR_PROG=$(printf "0x%x" $SERVICE_APP_ADDR)
CMD0="set image_bin ${SERV_APP}/${SERV_APP}_signed.bin"
CMD1="set image_size $SERVICE_APP_SIZE"
CMD2="set ext_flash_addr $SERVICE_APP_ADDR_PROG"
CMD3="set encrypt 0"

# Program SERVICE APP into the external memory
echo_run $OPENOCD_PATH/bin/openocd.exe -s $OPENOCD_PATH_WIN/scripts -c "$CMD0; $CMD1; $CMD2; $CMD3" -f cyapp_flash_loader.tcl