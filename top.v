module top(
	// icoboard 100mhz clock
	input clk_100mhz,

	//output led1, led2, led3,

	// PMOD P1 I/Os
	input exi_sck, exi_cs, exi_mosi,
	output exi_miso,

	// RPi GPIOs
	input rpi_mosi, rpi_sck, rpi_cs, 
	output rpi_miso,
);

wire clk_25mhz;
wire pll_locked;

// Presumably we can run at 25mhz? Does it need to be faster?
SB_PLL40_PAD #(
	.FEEDBACK_PATH("SIMPLE"),
	.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
	.DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
	.PLLOUT_SELECT("GENCLK"),
	.FDA_FEEDBACK(4'b1111),
	.FDA_RELATIVE(4'b1111),
	.DIVR(4'b0000),
	.DIVF(7'b0000111),
	.DIVQ(3'b101),
	.FILTER_RANGE(3'b101)
) pll (
	.PACKAGEPIN   (clk_100mhz),
	.PLLOUTGLOBAL (clk_25mhz ),
	.LOCK         (pll_locked),
	.BYPASS       (1'b0      ),
	.RESETB       (1'b1      )
);


// rPI 
// ----------------------------------------------------------------------------

reg [7:0] rpi_byte;
wire rpi_rx_done;
wire [7:0] rpi_rx;
wire rpi_tx_start;
wire [7:0] rpi_tx;
reg [7:0] total_rpi_rx_ctr;	// total number of bytes read
reg [7:0] cs_rpi_rx_ctr;	// number of bytes read in this CS


reg [15:0] cmd;
reg rpi_cmd_done;

reg [7:0] buffer[0:255];
reg [7:0] write_addr;
reg [7:0] read_addr;

// True after we've read two bytes
always @(posedge clk_25mhz) rpi_cmd_done = (cs_rpi_rx_ctr >= 2);
always @(posedge clk_25mhz) if(cs_rpi_rx_ctr >= 2) read_addr = cs_rpi_rx_ctr -2;

// Handle rPI rx
always @(posedge clk_25mhz) begin
	if(rpi_rx_done) begin
		rpi_byte = rpi_rx;
		total_rpi_rx_ctr = total_rpi_rx_ctr + 1;

		// Get 16-bit rPI cmd
		if (cs_rpi_rx_ctr <= 2) begin
			cmd = { cmd[7:0], rpi_byte };
		end

	end
end


// Handle rPI tx
always @(posedge clk_25mhz) begin
	if(rpi_tx_start) begin
		// Handle commands
		if (rpi_cmd_done == 1) begin
			if (cmd == 16'h0001) begin
				rpi_tx = buffer[read_addr];
			end
		end
		else begin
			rpi_tx = 8'h00;
		end
	end
end

// Handle SPI over rPI GPIOs
spi rpi(
	.clk(clk_25mhz),

	.sck(rpi_sck), 
	.cs(rpi_cs), 
	.mosi(rpi_mosi),
	.miso(rpi_miso),

	.rx_done(rpi_rx_done),
	.rx(rpi_rx),
	.rx_cnt(cs_rpi_rx_ctr),

	.tx_start(rpi_tx_start),
	.tx(rpi_tx),
);



gecko exi(
	.clk(clk_25mhz),

	.sck(exi_sck), 
	.cs(exi_cs), 
	.mosi(exi_mosi),
	.miso(exi_miso),

	//.rx_done(exi_rx_done),
	//.rx(exi_rx),
	//.rx_cnt(cs_exi_rx_ctr),

	//.tx_start(exi_tx_start),
	//.tx(exi_tx),
);

endmodule
