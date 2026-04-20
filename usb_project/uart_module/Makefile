# Project setup
PROJ      = top
SOURCES   = top.v uart_tx.v uart_rx.v fifo.v
PCF       = icebreaker.pcf
DEVICE    = up5k
PACKAGE   = sg48

# Simulation setup
SIM_SOURCES = tb_top.v $(SOURCES)
SIM_EXE     = ds_sim
VCD_FILE    = dump.vcd

# Tools
YOSYS    = yosys
NEXTPNR  = nextpnr-ice40
ICEPACK  = icepack
ICEPROG  = iceprog
IVERILOG = iverilog
VVP      = vvp
GTKWAVE  = gtkwave

# Default target: build the bitstream
all: $(PROJ).bin

# Synthesis
$(PROJ).json: $(SOURCES)
	$(YOSYS) -p "synth_ice40 -top $(PROJ) -json $@" $(SOURCES) > compile.log 2>&1

# Place and Route
$(PROJ).asc: $(PROJ).json $(PCF)
	$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --json $< --pcf $(PCF) --asc $@

# Pack bitstream
$(PROJ).bin: $(PROJ).asc
	$(ICEPACK) $< $@

# Flash to hardware
flash: $(PROJ).bin
	$(ICEPROG) $<

# Simulation
sim: $(SIM_SOURCES)
	$(IVERILOG) -o $(SIM_EXE) $(SIM_SOURCES)
	$(VVP) $(SIM_EXE)
# only need to run if GTKWAVE is not running yet or if the VCD file is not open in GTKWAVE
#	$(GTKWAVE) $(VCD_FILE)

# Cleanup
clean:
	rm -f $(PROJ).json $(PROJ).asc $(PROJ).bin $(SIM_EXE) $(VCD_FILE)

.PHONY: all flash sim clean