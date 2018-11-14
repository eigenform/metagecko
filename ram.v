
/* Naive DPRAM implementation */

module ram(
	input wire clk, 

	input wire [7:0] addr_0,
	inout wire [7:0] data_0,
	input wire cs_0, wren_0, oen_0,

	input wire [7:0] addr_1,
	inout wire [7:0] data_1,
	input wire cs_1, wren_1, oen_1,
);

	// Temporary registers for data output
	reg [7:0] data_0_out;
	reg [7:0] data_1_out;

	// Actual memory
	reg [7:0] mem [0:255];

	// Handle writes from port 0 and 1
	always @(posedge clk) begin
		if (cs_0 && wren_0) begin
			mem[addr_0] <= data_0;
		end 
		else if (cs_1 && we_1) begin
			mem[addr_1] <= data_1;
		end
	end

	// If port 0 [output] is enabled, continuously write output on the bus
	assign data_0 = (cs_0 && oen_0 && !wren_0) ? data_0_out : 8'bz;

	// Handle reads from port 0
	always @(posedge clk) begin
		if (cs_0 && !wren_0 && oen_0) begin
			data_0_out <= mem[addr_0];
		end
		else begin
			data_0_out <= 0;
		end
	end

	// If port 1 [output] is enabled, continuously write output on the bus
	assign data_1 = (cs_1 && oen_1 && !wren_1) ? data_1_out : 8'bz;

	// Handle reads from port 1
	always @(posedge clk) begin
		if (cs_1 && !wren_1 && oen_1) begin
			data_1_out <= mem[addr_1];
		end
		else begin
			data_1_out <= 0;
		end
	end

endmodule
