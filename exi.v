
/* EXI operates with CPOL=0, CPHA=0
 * (exi_clk is low when idle, data sampled on rising edge).
 * 
 * We use some other clk (from icoboard) to sample the EXI wires
 * to have some representation of state. I think this means that,
 * as long as clk is faster than the EXI master (32mhz), we'll 
 * always succeed in sampling MOSI?
 */

module exi(
	input wire clk, 

	input wire sck, cs, mosi, miso, 

	output wire [7:0] data_out, 
	inout wire [7:0] addr_out, 
	output wire ram_cs, ram_wren,

	output led,
);

	wire byte_done;		// high when we are done reading a whole byte
	reg [2:0] sckr, csr;	// encode sck/cs state in a register
	reg [1:0] mosir;	// keep MOSI bit in a register too

	reg [$clog2(8)-1:0] bits_remain; // bits left in a whole byte to-be-read
	reg [7:0] data;		// 8-bit register for impinging MOSI data
	reg [7:0] addr;		// increment this for each byte we read


	/* When we've recieved a full byte, we need to drive ram_wren, ram_cs,
	 * data_out, and addr_out in order to issue a write on the DPRAM module 
	 */

	assign ram_wren = byte_done;
	assign ram_cs = byte_done;
	assign addr_out = addr;
	assign data_out = data;


	// Detect the EXI clk
	always @(posedge clk) sckr <= {sckr[1:0], sck};
	wire sck_rising = (sckr[2:1] == 2'b01);
	wire sck_falling = (sckr[2:1] == 2'b10);

	// Detect CS 
	always @(posedge clk) csr <= {csr[1:0], cs};
	wire cs_active = !csr[1];
	wire startmsg = (csr[2:1]==2'b10);
	wire endmsg = (csr[2:1]==2'b01);
	assign led = cs_active;	// cs_active -> LED output

	// Always sample the current bit from MOSI
	always @(posedge clk) mosir <= {mosir[0], mosi};
	wire mosi_data = mosir[1];

	// Shift MOSI bits into a register (as long as we haven't filled it)	
	always @(posedge clk) begin
		if(!cs_active) begin
			bits_remain <= 7;
			data <= 0;
		end else if(sck_rising) begin
			data <= {data[6:0], mosi_data};
			bits_remain <= (bits_remain == 0) ? 7 : bits_remain -1;
		end
		byte_done <= (cs_active && sck_rising && bits_remain == 0);
		if (byte_done)
			addr <= addr + 1;
	end

	//reg [7:0] byte_data_sent;
	//reg [7:0] cnt;
	//always @(posedge clk) begin
	//	if(startmsg) 
	//		cnt <= cnt + 8'h1;
	//end
	//always @(posedge clk)
	//	if(cs_active)
	//	begin
	//		if (startmsg)
	//			byte_data_sent <= cnt;
	//		else 
	//		if (sck_falling)
	//		begin
	//			if (bits_remain == 7)
	//				byte_data_sent <= 8'h00;
	//			else
	//				byte_data_sent <= {byte_data_sent[6:0], 1'b0};
	//		end
	//	end
	//assign miso = byte_data_sent[7];

endmodule
