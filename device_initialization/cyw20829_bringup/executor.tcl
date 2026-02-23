#!/usr/local/bin/openocd2

# Default parameters values
dict set app_data image_path dummy.bin
dict set app_data in_params_addr 0x2000D000
dict set app_data in_data {}
dict set app_data out_params_addr 0x20003000
dict set app_data out_data {}
dict set app_data out_data_size 0
# A timeout in 100 ms units, e.g. 100 means 100 * 100ms = 10_000 ms = 10 sec
dict set app_data wait_for_app_timeout 200
dict set app_data reset_after_app_cmplt 0

# Check if we have specific folder as argument
if {0 == [info exists app_folder]} {
    set app_folder "."
    puts "\nUsing current folder \"[pwd]\""
} else {
    puts "\nUsing app folder \"$app_folder\""
}

# Check if we have specific config as argument
if {0 == [info exists config_file]} {
    set config_file config.conf
    puts "\nUsing default config file \"$config_file\""
} else {
    puts "\nUsing config file \"$config_file\""
}

set config_file $app_folder/$config_file

# Parsing config file parameters and overwrite app_data
foreach line [split [read [open $config_file]] \n] {
    if {[string match "#*" $line]} {
        # This is commented string
    } else {
        if {[regexp {^([^=]*)=(.*)$} $line -> key value]} {
            dict set app_data $key $value
        } else {
            # "=" absent in the line
        }
    }
}

# Parameters that could be changed using config file
set image_file             $app_folder/[dict get $app_data image_path]
set in_data_file           [dict get $app_data in_data]
set out_data_file          [dict get $app_data out_data]
set out_data_size          [dict get $app_data out_data_size]
set in_data_addr           [dict get $app_data in_params_addr]
set out_data_addr          [dict get $app_data out_params_addr]
set wait_for_app_timeout   [dict get $app_data wait_for_app_timeout]
set reset_after_app_cmplt  [dict get $app_data reset_after_app_cmplt]

# Address to put application signed image in MCUBoot format
set IMAGE_SLOT_START_ADDR  0x20004000

# Hardware registers
set TST_DEBUG_CTL    0x40200404
set TST_DEBUG_STATUS 0x40200408
set RES_SOFT_CTL     0x40200410
set EFUSE_BOOTROW    0x40810180

# Registers constants
set RES_SOFT_CTL_RESET_RQST 0x00000001
set TST_DBG_CTL_WAIT_RAM_APP_RQST 0x00000001
set TST_DBG_CTL_WFA_Msk 0x80000000

# Intermidiate states returned using TST_DEBUG_STATUS
set CYBOOT_WFA_POLLING      0x0D500080
set CYBOOT_SERVICE_APP_LAUNCHED     0x0D500081
set CYBOOT_SERVICE_APP_NOT_LAUNCHED 0x0D500082
set CYAPP_APP_RUNNING      0xF2A00010

set EXIT_DUE_ERROR 1
set DEFAULT_TIME_OUT_MS 100

# Interface settings
# Uncomment when power supply enabling not needed
# set ENABLE_POWER_SUPPLY 0
set ENABLE_ACQUIRE 0

# Only one interface should be selected (uncommented). Other left for reference.
# source [find interface/jlink.cfg]
# source [find interface/kitprog3.cfg]
source [find interface/cmsis-dap.cfg]

transport select swd
source [find target/infineon/cyw20829.cfg]

# Disable polling CM33 core
# This operation needed when SYS_AP used
cyw20829.cm33 configure -defer-examine

adapter speed 100
init
targets cyw20829.sysap

puts "\n"

set bootrow [expr { [mrw $EFUSE_BOOTROW] & 0xFFFF }]
set is_virgin_lcs  [expr { ($bootrow == 0) ? 1 : 0 }]
set is_sort_lcs    [expr { ($bootrow == 0x0029) ? 1 : 0 }]
set is_rma_lcs     [expr { (($bootrow & 0x3000) == 0x3000) ? 1 : 0 }]
set has_slow_clock [expr { $is_virgin_lcs || $is_sort_lcs || $is_rma_lcs }]

# Timeout [seconds] = 14e+6 [#clock for RSA signature] / CLK_FREQ [Hz]
# For IMO, CLK_FREQ=8 MHz
# For IHO, CLK_FREQ=50 MHz
# Add some margin (10-20%) to a timeout
set wfa_img_verify_timeout  [expr { $has_slow_clock ? 2000 : 250 }]

# VIRGIN & RMA LCS: the WFA bit is set, the BootROM is waiting for application.
# Thus, no reason to reset a device.
# For other LCS, post a request and reset a device then wait for TST_DBG_CTL_WFA_Msk.
if {(([mrw $TST_DEBUG_CTL] & $TST_DBG_CTL_WFA_Msk) == 0)} {

    # Post request to BootROM to stop and wait for application after reset
    puts "Write TST_DEBUG_CTL.REQUEST = 0x001 and reset the device using RES_SOFT_CTL.TRIGGER_SOFT = 1"
    mww $TST_DEBUG_CTL $TST_DBG_CTL_WAIT_RAM_APP_RQST

    # Reset device using $RES_SOFT_CTL register.
    # The mww command fails so catch this fail and continue
    local_echo off
    catch { mww $RES_SOFT_CTL $RES_SOFT_CTL_RESET_RQST }
    local_echo on

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

if {([mrw $TST_DEBUG_STATUS] != $CYBOOT_WFA_POLLING)} {
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

# Loading input paramaters to be used by application
if {"$in_data_file" != ""} {
    if {[file size $app_folder/$in_data_file] > 8} {
        puts "\nProgramming application input parameters $in_data_file to $in_data_addr"
        load_image   $app_folder/$in_data_file  $in_data_addr
    } else {
        puts "\nERROR Input parameters $in_data_file should have size larger then 8 bytes"
        exit $EXIT_DUE_ERROR
    }
}

puts "Set SRSS_TST_DEBUG_CTL.WFA = 0 to start BootROM execution"
mww $TST_DEBUG_CTL 0
puts "Waiting for application completion..."
sleep $wfa_img_verify_timeout ; # No debugger communication until DAP is re-enabled

# The BootROM disconnect debugger is after application was placed in RAM to
# update RAM protection settings. So, the TST_DEBUG_STATUS read operation fails.
# Wait until debugger is connected and TST_DEBUG_STATUS is changed.
set timeout 0
set tmp_status $CYBOOT_WFA_POLLING
while {$tmp_status == $CYBOOT_WFA_POLLING} {
    incr timeout 1
    if {$timeout > $wait_for_app_timeout} {
        if {$tmp_status == $CYBOOT_WFA_POLLING} {
            puts [format "FAIL: BootROM did not pass control to application - timeout, status = 0x%08X" $tmp_status]
        }

        exit $EXIT_DUE_ERROR
    }
    sleep $DEFAULT_TIME_OUT_MS

    # Set tmp_status previous value if read operation failed (debugger still disconnected)
    if { [catch { set tmp_status [mrw $TST_DEBUG_STATUS] }] } {
        set tmp_status $CYBOOT_WFA_POLLING
    }
}

# Wait for application completion if it was laucned by the BootROM
while {($tmp_status == $CYBOOT_SERVICE_APP_LAUNCHED)
    || ($tmp_status == $CYAPP_APP_RUNNING)} {
    incr timeout 1
    if {$timeout > $wait_for_app_timeout} {
        if {$tmp_status == $CYBOOT_WFA_POLLING} {
            puts [format "FAIL: BootROM did not pass control to application - timeout, status = 0x%08X" $tmp_status]
        } elseif {$tmp_status == $CYAPP_APP_RUNNING} {
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
if {$tmp_status == $CYBOOT_SERVICE_APP_NOT_LAUNCHED} {
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

reset

shutdown
