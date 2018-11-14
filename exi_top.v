// EXI 
// ----------------------------------------------------------------------------

/* I think this is the way you'd implement traditional EXI commands (using the
 * spi.v module). You could use this to implement your own EXI device.
 * Gecko seems different/noncompliant in the sense that the VHDL 
 * implementations (and thus, libogc) require you to deal with the 
 * EXI_READWRITE mode, implying that the underlying logic is bitwise, not with 
 * bytes like this. Should keep this template around.
 */

//reg [7:0] exi_byte;
//wire exi_rx_done;
//wire [7:0] exi_rx;
//wire exi_tx_start;
//wire [7:0] exi_tx;
//reg [7:0] total_exi_rx_ctr;	// total number of bytes read
//reg [7:0] cs_exi_rx_ctr;	// number of bytes read in this CS
//
//reg [15:0] exi_cmd;
//reg [31:0] exi_id = 32'h04700000;
//reg [31:0] exi_tx_buf;
//reg exi_resp_start;
//reg exi_cmd_done;
//
//// True after we've read two bytes
//always @(posedge clk_25mhz) exi_cmd_done = (cs_exi_rx_ctr >= 2);
//always @(posedge clk_25mhz) exi_resp_start = (cs_exi_rx_ctr == 2);
//
//// Handle EXI rx/tx signals
//always @(posedge clk_25mhz) begin
//	if(exi_rx_done) begin
//		// Write data from cube + our resp into buffer
//		exi_byte = exi_rx;
//		buffer[write_addr] = exi_byte;
//		write_addr = write_addr + 1;
//
//		// Get 16-bit EXI cmd
//		if (cs_exi_rx_ctr <= 2) begin
//			exi_cmd = { exi_cmd[7:0], exi_byte };
//		end
//
//	end
//end
//
//always @(posedge clk_25mhz) begin
//	if(exi_tx_start) begin
//		//if (exi_cmd_done == 1) begin
//		//	if (exi_cmd == 16'h0000) begin
//		//		if (cs_exi_rx_ctr == 2)
//		//			//exi_tx = exi_id[31:24];
//		//			exi_tx = 8'h00;
//		//		if (cs_exi_rx_ctr == 3)
//		//			//exi_tx = exi_id[23:16];
//		//			exi_tx = 8'h00;
//		//		if (cs_exi_rx_ctr == 4)
//		//			//exi_tx = exi_id[15:8];
//		//			exi_tx = 8'h00;
//		//		if (cs_exi_rx_ctr == 5)
//		//			//exi_tx = exi_id[7:0];
//		//			exi_tx = 8'h00;
//		//	end
//		//	if (exi_cmd == 16'hdead) begin
//		//		if (cs_exi_rx_ctr == 2)
//		//			exi_tx = 8'hbe;
//		//		if (cs_exi_rx_ctr == 3)
//		//			exi_tx = 8'hef;
//		//	end
//		//end
//		// Otherwise, just send 0x01
//		//else begin
//		//	exi_tx <= 8'h01;
//		//end
//	end
//end
//
//// Handle SPI over the EXI GPIOs
//spi exi(
//	.clk(clk_25mhz),
//
//	.sck(exi_sck), 
//	.cs(exi_cs), 
//	.mosi(exi_mosi),
//	.miso(exi_miso),
//
//	.rx_done(exi_rx_done),
//	.rx(exi_rx),
//	.rx_cnt(cs_exi_rx_ctr),
//
//	.tx_start(exi_tx_start),
//	.tx(exi_tx),
//);

