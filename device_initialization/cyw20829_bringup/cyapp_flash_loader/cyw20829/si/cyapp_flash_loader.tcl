#!/usr/local/bin/openocd2

# Command line options:
# image_bin - Path to the image and image name for programming.
#             The image must be compiled to run in the address space 0x30040000-0x30060000.
# image_size - Image size in bytes.
# ext_flash_addr - External flash memory start address to program image.
#                  This address must match with SMIF_CONFIG[1] stored in OTP.
#                  Default address 0x0.
# encrypt - Image encryption.
#           0 = do not encrypt.
#           1 = encrypt the image.
# smif_crypto_cfg - optional 96bit nonce.
#                   "NONE"= use all zeros for nonce.
#                   "filename.bin" = binary file containing 96bit nonce.

# Default parameters values
set in_params_base          0x20009000
set image_file              cyapp_flash_loader_signed_icv0.bin
set reset_after_app_cmplt   0
set wait_for_app_timeout    100

# Address to put application signed image in MCUBoot format
set IMAGE_SLOT_START_ADDR  0x20004000

# Hardware registers
set TST_DEBUG_CTL    0x40200404
set TST_DEBUG_STATUS 0x40200408
set RES_SOFT_CTL     0x40200410

# Registers constants
set RES_SOFT_CTL_RESET_RQST 0x00000001
set TST_DBG_CTL_WAIT_RAM_APP_RQST 0x00000001
set TST_DBG_CTL_WFA_Msk 0x80000000

# Intermidiate states returned using TST_DEBUG_STATUS
set TST_DBG_STS_RAM_APP_WFA_SET      0x0D500080
set TST_DBG_STS_RAM_APP_LAUNCHED     0x0D500081
set TST_DBG_STS_RAM_APP_NOT_LAUNCHED 0xBAF00082
set TST_DBG_STS_RAM_APP_RUNNING      0xF2A00010

set EXIT_DUE_ERROR 1
set DEFAULT_TIME_OUT_MS 200

# Interface settings
# Uncomment when power supply enabling not needed
# set ENABLE_POWER_SUPPLY 0
set ENABLE_ACQUIRE 0

# Only one interface should be selected (uncommented). Other left for reference.
# source [find interface/jlink.cfg]
# source [find interface/kitprog3.cfg]
source [find interface/cmsis-dap.cfg]

transport select swd
source [find target/cyw20829.cfg]

# Disable polling CM33 core
# This operation needed when SYS_AP used
${TARGET}.cm33 configure -defer-examine

adapter speed 100
init
targets $_CHIPNAME.sysap

puts "\n"
# If WFA bit set, the BootROM is waiting for application.
# Otherwise, post request and reset the device.
if {(([mrw $TST_DEBUG_CTL] & $TST_DBG_CTL_WFA_Msk) == 0)} {

    # Post request to BootROM to stop and wait for application after reset
    puts "Write TST_DEBUG_CTL.REQUEST = 0x001 and reset the device using RES_SOFT_CTL.TRIGGER_SOFT = 1"
    mww $TST_DEBUG_CTL $TST_DBG_CTL_WAIT_RAM_APP_RQST

    # Reset device using $RES_SOFT_CTL register.
    # The mww command fails so catch this fail and continue
    catch { mww $RES_SOFT_CTL $RES_SOFT_CTL_RESET_RQST }

    puts "Waiting until BootROM stopped and read for application upload..."
}

# Check if BootROM waits for application
set timeout 0
while {(([mrw $TST_DEBUG_CTL] & $TST_DBG_CTL_WFA_Msk) == 0)} {
    incr timeout 1
    if {$timeout > $wait_for_app_timeout} {
        puts "FAIL: BootROM did not set flag waiting for application - timeout"
        exit $EXIT_DUE_ERROR
    }
    sleep $DEFAULT_TIME_OUT_MS
}

if {([mrw $TST_DEBUG_STATUS] != $TST_DBG_STS_RAM_APP_WFA_SET)} {
    puts "FAIL: BootROM did not set expected TST_DEBUG_STATUS"
    puts [format "    TST_DEBUG_STATUS: 0x%08X;" [mrw $TST_DEBUG_STATUS]]
    puts [format "    TST_DEBUG_CTL: 0x%08X;"  [mrw $TST_DEBUG_CTL]]
    exit 1
} else {
    puts "Ready for application programming!"
}

# Loading application
puts "Programming application: $image_file to $IMAGE_SLOT_START_ADDR"
load_image $image_file $IMAGE_SLOT_START_ADDR

#Load the data and image for programming
set cfg_apply_smif_config_offset   [expr {$in_params_base + 0x00}]
set cfg_smif_config0_offset        [expr {$in_params_base + 0x04}]
set cfg_smif_config1_offset        [expr {$in_params_base + 0x08}]
set cfg_smif_key0_offset           [expr {$in_params_base + 0x0C}]
set cfg_smif_key1_offset           [expr {$in_params_base + 0x10}]
set cfg_smif_key2_offset           [expr {$in_params_base + 0x14}]
set cfg_smif_key3_offset           [expr {$in_params_base + 0x18}]
set cfg_smif_nonce0_offset         [expr {$in_params_base + 0x1C}]
set cfg_smif_nonce1_offset         [expr {$in_params_base + 0x20}]
set cfg_smif_nonce2_offset         [expr {$in_params_base + 0x24}]
set cfg_flash_addr_offset          [expr {$in_params_base + 0x28}]
set cfg_image_size_offset          [expr {$in_params_base + 0x2C}]
set cfg_image_offset               [expr {$in_params_base + 0x30}]

# SMIF_CONFIG settings. Set smif_ext_config_provided to 1 to override OTP settings
set smif_ext_config_provided 0x00000001
if {(1 == $encrypt)} {
    set SMIF_CONFIG_0            0x00000244
} else {
    set SMIF_CONFIG_0            0x00000204
}
set SMIF_CONFIG_1            0x00000000
set SMIF_KEY_0               0x702B2A6D
set SMIF_KEY_1               0xED9005F8
set SMIF_KEY_2               0x1EFE880D
set SMIF_KEY_3               0x8775481D
set SMIF_NONCE_0             0x00000000
set SMIF_NONCE_1             0x00000000
set SMIF_NONCE_2             0x00000000

puts "Programming application input parameters to $cfg_apply_smif_config_offset"
mww $cfg_apply_smif_config_offset  $smif_ext_config_provided
mww $cfg_smif_config0_offset       $SMIF_CONFIG_0
mww $cfg_smif_config1_offset       $SMIF_CONFIG_1
mww $cfg_smif_key0_offset          $SMIF_KEY_0
mww $cfg_smif_key1_offset          $SMIF_KEY_1
mww $cfg_smif_key2_offset          $SMIF_KEY_2
mww $cfg_smif_key3_offset          $SMIF_KEY_3

# Path to the nonce file programming (the extension must be bin)
if ![info exists smif_crypto_cfg] {
    set smif_crypto_cfg "NONE"
}

# Load nonce from file, if present.
# File size must be >=16 bytes for OpenOCD. Only 1st 12 bytes used.
if {"NONE" != $smif_crypto_cfg} {
    puts "Nonce provided in file ${smif_crypto_cfg}.bin"
    load_image   "${smif_crypto_cfg}.bin" $cfg_smif_nonce0_offset
} else {
    mww $cfg_smif_nonce0_offset        $SMIF_NONCE_0
    mww $cfg_smif_nonce1_offset        $SMIF_NONCE_1
    mww $cfg_smif_nonce2_offset        $SMIF_NONCE_2
}
mww $cfg_flash_addr_offset         $ext_flash_addr
mww $cfg_image_size_offset         $image_size

puts "Programming image $image_bin (size $image_size) to be written in external memory addr $ext_flash_addr"
load_image   $image_bin $cfg_image_offset

puts "Set SRSS_TST_DEBUG_CTL.WFA = 0 to start BootROM execution"
mww $TST_DEBUG_CTL 0

puts "Waiting for application completion..."
# The BootROM disconnect debugger is after application was placed in RAM to
# update RAM protection settings. So, the TST_DEBUG_STATUS read operation fails.
# Wait until debugger is connected and TST_DEBUG_STATUS is changed.
set timeout 0
set tmp_status $TST_DBG_STS_RAM_APP_WFA_SET
while {$tmp_status == $TST_DBG_STS_RAM_APP_WFA_SET} {
    incr timeout 1
    if {$timeout > $wait_for_app_timeout} {
        if {$tmp_status == $TST_DBG_STS_RAM_APP_WFA_SET} {
            puts [format "FAIL: BootROM did not pass control to application - timeout, status = 0x%08X" $tmp_status]
        }

        exit $EXIT_DUE_ERROR
    }
    sleep $DEFAULT_TIME_OUT_MS

    # Set tmp_status previous value if read operation failed (debugger still disconnected)
    if { [catch { set tmp_status [mrw $TST_DEBUG_STATUS] }] } {
        set tmp_status $TST_DBG_STS_RAM_APP_WFA_SET
    }
}

# Wait for application completion if it was laucned by the BootROM
while {($tmp_status == $TST_DBG_STS_RAM_APP_LAUNCHED)
    || ($tmp_status == $TST_DBG_STS_RAM_APP_RUNNING)} {
    incr timeout 1
    if {$timeout > $wait_for_app_timeout} {
        if {$tmp_status == $TST_DBG_STS_RAM_APP_WFA_SET} {
            puts [format "FAIL: BootROM did not pass control to application - timeout, status = 0x%08X" $tmp_status]
        } elseif {$tmp_status == $TST_DBG_STS_RAM_APP_RUNNING} {
            puts [format "FAIL: Application did not return - timeout, status = 0x%08X" $tmp_status]
        } else {
            puts [format "FAIL: unexpected reason of faliure - timeout, status = 0x%08X" $tmp_status]
        }
        exit $EXIT_DUE_ERROR
    }
    sleep $DEFAULT_TIME_OUT_MS

    set tmp_status [mrw $TST_DEBUG_STATUS]
}

# Application is either completed or was not launched
if {$tmp_status == $TST_DBG_STS_RAM_APP_NOT_LAUNCHED} {
    puts [format "FAIL: BootROM did not launch application due verification failure, status = 0x%08X" $tmp_status]
} else {
    puts [format "Application execution completed status: 0x%08X" $tmp_status]
}

if {$reset_after_app_cmplt == 1} {
    puts "Reset device"
    # Reset device using $RES_SOFT_CTL register.
    # The mww command fails so catch this fail and continue
    catch { mww $RES_SOFT_CTL $RES_SOFT_CTL_RESET_RQST }
}

puts "\nSuccess"
shutdown
