set ENABLE_ACQUIRE 0

source [find interface/cmsis-dap.cfg]

transport select swd

source [find target/infineon/cyw20829.cfg]

cyw20829.cm33 configure -defer-examine

adapter speed 100

init

targets cyw20829.cm33

reset init

load_image cyw20829_bringup/toggle_test.hex

mww 0x40161004 0x20004200
mww 0x40160004 0x05FA0000

sleep 2000

mdw 0x20001008

shutdown
