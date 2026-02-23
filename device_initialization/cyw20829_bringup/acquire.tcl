#!/usr/local/bin/openocd2

# Check if we have specific folder as argument
if {0 == [info exists app_folder]} {
    set app_folder "."
    puts "\nUsing current folder \"[pwd]\""
} else {
    puts "\nUsing app folder \"$app_folder\""
}

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

targets cyw20829.cm33

init

reset init

mww 0x40810000 0x80000000

puts "*********************************************"
puts "*                ACTUAL EFUSE               *"
puts "*********************************************"
mdw 0x40810800
mdw 0x40810804
mdw 0x40810808
mdw 0x4081080C
mdw 0x40810810
mdw 0x40810814
mdw 0x40810818
mdw 0x4081081C
mdw 0x40810820
mdw 0x40810824
mdw 0x40810828
mdw 0x4081082C
mdw 0x40810830
mdw 0x40810834
mdw 0x40810838
mdw 0x4081083C
mdw 0x40810840
mdw 0x40810844
mdw 0x40810848
mdw 0x4081084C
mdw 0x40810850
mdw 0x40810854
mdw 0x40810858
mdw 0x4081085C
mdw 0x40810860
mdw 0x40810864
mdw 0x40810868
mdw 0x4081086C
mdw 0x40810870
mdw 0x40810874
mdw 0x40810878
mdw 0x4081087C

reset

shutdown
