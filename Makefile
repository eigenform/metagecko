TARGET 	:= metagecko

#SRC	:= rpi_spi.v spram.v exi_spi.v
SRC	:= spi.v gecko.v

all: $(TARGET).bin

$(TARGET).blif: top.v $(SRC)
	yosys -p 'synth_ice40 -blif $(TARGET).blif' top.v $(SRC) 

$(TARGET).asc: $(TARGET).blif icoboard.pcf
	arachne-pnr -d 8k -p icoboard.pcf -o $(TARGET).asc $(TARGET).blif

$(TARGET).bin: $(TARGET).asc
	icetime -d hx8k -c 25 $(TARGET).asc
	icepack $(TARGET).asc $(TARGET).bin
clean:
	@rm -f $(TARGET).blif $(TARGET).asc $(TARGET).bin

.PHONY: clean
