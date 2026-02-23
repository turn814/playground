:: Usage
:: FW_download.bat COMxxx "C:\path\to\fw"

@echo off
setlocal ENABLEDELAYEDEXPANSION

set com_port=%1
set fw_directory=%2

set orig_dir=%cd%

Rem openocd
cd C:\Users\irvinelabuser\ModusToolbox\tools_3.2\openocd\bin
echo Loading HCI App...
openocd.exe -s ../scripts -c "set ENABLE_ACQUIRE o" -f interface/kitprog3.cfg -f target/mxs40/cyw20829_common.cfg -c "init;reset init;reg pc [mrw 0xc004]; reg sp [mrw 0xc000]; resume; shutdown"
echo Loaded HCI App!

cd %fw_directory%

Rem FW download
echo Downloading FW...
for %%f in (*.hex) do (
set hex_file=%%f
)
ChipLoad.exe -BLUETOOLMODE -PORT %com_port% -BAUDRATE 115200 -CONFIG %hex_file% -BTP 20829B0.btp -NOERASE

cd "%orig_dir%"