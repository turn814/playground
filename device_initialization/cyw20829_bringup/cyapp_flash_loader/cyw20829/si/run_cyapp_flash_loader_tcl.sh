#!/bin/bash

# Configure to run openocd from cygwin
OPENOCD_PATH_WIN="$OPENOCD"
OPENOCD_PATH=`cygpath -u $OPENOCD_PATH_WIN`

echo_run() { echo "\$ ${@/eval/}" ; "$@" ; }

# Flash loader configuration
LCS=${1:-"NSEC"}

# Path to the image (the extension must be bin)
L1_APP=${2:-"cyapp_blinky_led"}

# Key name used to sign image (options: oem0, oem1)
L1_KEY=${3:-"oem0"}

# Path to the smif_crypto_cfg and its name for programming (the extension
# must be bin)
SMIF_CRYPTO_CFG=${4:-"NONE"}

####################### Check required files ###################################

FILE=${L1_APP}.bin
if [[ ! -f "$FILE" ]]; then
    echo "$FILE does not exist."
    exit
fi

FILE=${L1_APP}_signed_${L1_KEY}.bin
if [[ ! -f "$FILE" && "$LCS" != "NSEC" ]]; then
    echo "$FILE does not exist."
    exit
fi

if [[ "$SMIF_CRYPTO_CFG" != "NONE" ]]; then
    FILE=${SMIF_CRYPTO_CFG}.bin
    if [ ! -f "$FILE" ]; then
        echo "$FILE does not exist."
        exit
    fi
fi

################################ Functions #####################################

function hex_str_to_bin() {
  printf "\x${1:6:2}"
  printf "\x${1:4:2}"
  printf "\x${1:2:2}"
  printf "\x${1:0:2}"
}

######################### Generate TOC2 ########################################

# Hardcoded TOC2 size
TOC2_SIZE=16

# Hardcoded address in external memory
TOC2_ADDR=0

# Hardcoded L1_APP_DESCR size
L1_APP_DESCR_SIZE=28

# TOC2 entries
L1_APP_DESCR_ADDR=$TOC2_SIZE
DEBUG_CERT_ADDR=4096
SERVICE_APP_DESCR_ADDR=8192

# Remove existing files
`rm -f toc2.bin`
`rm -f l1_app_descr.bin`

# Convert to hex string (without 0x prefix)
TOC2_SIZE_HEX=$(printf "%08x" $TOC2_SIZE)
L1_APP_DESCR_ADDR_HEX=$(printf "%08x" $L1_APP_DESCR_ADDR)
SERVICE_APP_DESCR_ADDR_HEX=$(printf "%08x" $SERVICE_APP_DESCR_ADDR)
DEBUG_CERT_ADDR_HEX=$(printf "%08x" $DEBUG_CERT_ADDR)

# Write 4 bytes from hex string, LSB first
hex_str_to_bin $TOC2_SIZE_HEX >  toc2.bin
hex_str_to_bin $L1_APP_DESCR_ADDR_HEX >> toc2.bin
hex_str_to_bin $SERVICE_APP_DESCR_ADDR_HEX >> toc2.bin
hex_str_to_bin $DEBUG_CERT_ADDR_HEX >> toc2.bin

######################### Generate L1_APP_DESCR ################################

BOOT_STRAP_SRC_ADDR=0xB000
BOOT_STRAP_DST_ADDR=0x2001E000
# For this case the L1 user application and bootstrap are the same
BOOT_STRAP_SIZE=`wc -c ${L1_APP}.bin | awk '{print $1}'`

# Convert to hex string (without 0x prefix)
L1_APP_DESCR_SIZE_HEX=$(printf "%08x" $L1_APP_DESCR_SIZE)
BOOT_STRAP_SRC_ADDR_HEX=$(printf "%08x" $BOOT_STRAP_SRC_ADDR)
BOOT_STRAP_DST_ADDR_HEX=$(printf "%08x" $BOOT_STRAP_DST_ADDR)
BOOT_STRAP_SIZE_HEX=$(printf "%08x" $BOOT_STRAP_SIZE)

# Write 4 bytes from hex string, LSB first
hex_str_to_bin $L1_APP_DESCR_SIZE_HEX > tmp.bin
hex_str_to_bin $BOOT_STRAP_SRC_ADDR_HEX >> tmp.bin
hex_str_to_bin $BOOT_STRAP_DST_ADDR_HEX >> tmp.bin
hex_str_to_bin $BOOT_STRAP_SIZE_HEX >> tmp.bin

if [[ "$SMIF_CRYPTO_CFG" == "NONE" ]]; then
    for var in 0 1 2
    do
        SMIF_CRYPTO_CFG_HEX=00000000
        hex_str_to_bin $SMIF_CRYPTO_CFG_HEX >> tmp.bin
    done

    `mv tmp.bin l1_app_descr.bin`
else
    `cat tmp.bin $SMIF_CRYPTO_CFG.bin > l1_app_descr.bin
     rm -f tmp.bin`
fi

############################# Program TOC2 #####################################

TOC2_ADDR_PROG=$(printf "0x%x" $TOC2_ADDR)
CMD0="set image_bin toc2.bin"
CMD1="set image_size $TOC2_SIZE"
CMD2="set ext_flash_addr $TOC2_ADDR_PROG"
CMD3="set encrypt 0"

# Program TOC2 object into the external memory
echo_run $OPENOCD_PATH/bin/openocd.exe -s $OPENOCD_PATH_WIN/scripts -c "$CMD0; $CMD1; $CMD2; $CMD3" -f cyapp_flash_loader.tcl

############################# Program L1_APP_DESCR #############################

L1_APP_DESCR_ADDR_PROG=$(printf "0x%x" $L1_APP_DESCR_ADDR)
CMD0="set image_bin l1_app_descr.bin"
CMD1="set image_size $L1_APP_DESCR_SIZE"
CMD2="set ext_flash_addr $L1_APP_DESCR_ADDR_PROG"
CMD3="set encrypt 0"

# Program L1_APP_DESCR object into the external memory
echo_run $OPENOCD_PATH/bin/openocd.exe -s $OPENOCD_PATH_WIN/scripts -c "$CMD0; $CMD1; $CMD2; $CMD3" -f cyapp_flash_loader.tcl

############################# Program L1 APP ###################################

if [[ "$LCS" == "NSEC" ]]; then
    L1_APP_SIZE=$BOOT_STRAP_SIZE
    CMD0="set image_bin ${L1_APP}.bin"
    CMD1="set image_size $L1_APP_SIZE"
    CMD3="set encrypt 0"
elif [ "$LCS" == "SEC_ENC" ]; then
    L1_APP_SIZE=`wc -c ${L1_APP}_signed_${L1_KEY}.bin | awk '{print $1}'`
    CMD0="set image_bin ${L1_APP}_signed_${L1_KEY}.bin"
    CMD1="set image_size $L1_APP_SIZE"
    CMD3="set encrypt 1"
else
    L1_APP_SIZE=`wc -c ${L1_APP}_signed_${L1_KEY}.bin | awk '{print $1}'`
    CMD0="set image_bin ${L1_APP}_signed_${L1_KEY}.bin"
    CMD1="set image_size $L1_APP_SIZE"
    CMD3="set encrypt 0"
fi
BOOT_STRAP_ADDR_PROG=$(printf "0x%x" $BOOT_STRAP_SRC_ADDR)
CMD2="set ext_flash_addr $BOOT_STRAP_ADDR_PROG"
CMD4="set smif_crypto_cfg $SMIF_CRYPTO_CFG"

# Program L1 application into the external memory
echo_run $OPENOCD_PATH/bin/openocd.exe -s $OPENOCD_PATH_WIN/scripts -c "$CMD0; $CMD1; $CMD2; $CMD3; $CMD4" -f cyapp_flash_loader.tcl