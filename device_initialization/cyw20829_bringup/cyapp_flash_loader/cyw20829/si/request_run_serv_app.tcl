#!/usr/local/bin/openocd2

# Hardware registers
set TST_DEBUG_CTL    0x40200404
set RES_SOFT_CTL     0x40200410

# Registers constants
set REQUEST_EXT_APP         0x3
set RES_SOFT_CTL_RESET_RQST 0x1

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

# Set BootROM request to launch service application from external memory and
# reset the device
mww $TST_DEBUG_CTL $REQUEST_EXT_APP
mdw $TST_DEBUG_CTL
mww $RES_SOFT_CTL $RES_SOFT_CTL_RESET_RQST

puts "\nSuccess"
shutdown
