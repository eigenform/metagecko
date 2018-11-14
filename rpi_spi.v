module rpi_spi(
	input clk,		// input reference clock
	input sck, cs, mosi,	// RPi GPIOs for SPI
	output miso,		// RPi GPIOs for SPI

	output [7:0] ram_addr,
	input [7:0] ram_data,

	input [7:0] exi_addr_track,
);

// The Raspberry Pi only supports 8-bit words [I think?]
localparam width = 8;
localparam mem_size = 64;


/* Use the reference clock to sample sck, cs, and mosi. This lets us easily
 * check their state in the {sck,cs,mosi}r registers.
 */

reg [2:0] sckr, csr;
reg [1:0] mosir;

always @(negedge clk) sckr <= {sckr[1:0], sck};
wire sck_rising = (sckr[2:1] == 2'b01);
wire sck_falling = (sckr[2:1] == 2'b10);

always @(negedge clk) csr <= {csr[1:0], cs};
wire cs_active = !csr[1];
wire cs_falling = (csr[2:1] == 2'b10);
wire cs_rising = (csr[2:1] == 2'b01);

always @(negedge clk) mosir <= {mosir[0], mosi};
wire mosi_data = mosir[1];


/* We need to use a couple different registers in order to keep track of
 * some state */

reg byte_done;				// set if done reading a byte
reg [$clog2(width)-1:0] bits_expected;	// bits we expect to read
reg [7:0] addr;	// index into buffer
reg [width-1:0] data;			// transient register for mosi
reg [7:0] byte_data_sent;		// transient register for miso


always @(negedge clk) begin
	if(!cs_active) begin
		bits_expected <= width - 1;
		addr <= 0;
		data <= 0;
	end
	else if(sck_rising) begin
		data <= {data[width-2:0], mosi_data};
		bits_expected <= (bits_expected == 0) ? width - 1 : bits_expected - 1;
	end
	
	byte_done <= (cs_active && sck_rising && bits_expected == 0);
	if (byte_done) begin
		addr <= addr + 1;
	end
end
assign ram_addr = addr;


always @(negedge clk) if (cs_active) begin
	if (cs_falling)
		//byte_data_sent <= 8'hee;
		byte_data_sent <= exi_addr_track + 1;
	else begin
		if (sck_falling) begin
			if (bits_expected == (width - 1))
				byte_data_sent <= ram_data;
			else
				byte_data_sent <= {byte_data_sent[6:0], 1'b0};
		end
	end
end
assign miso = byte_data_sent[7];


endmodule
