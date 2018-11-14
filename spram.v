module spram(
	input clk,

	input do_read,
	input do_write,

	input [7:0] read_addr,
	input [7:0] write_addr,

	output [7:0] read_data,
	input [7:0] write_data,
);

reg [7:0] mem[0:255];

always @(posedge clk) begin
	//if(do_read)
		//read_data <= mem[read_addr];
	read_data <= mem[read_addr];
end

always @(posedge clk) begin
	//if(do_write)
	//	mem[write_addr] <= write_data;
	mem[write_addr] <= write_data;
end

initial $readmemh("ram_init.cfg", mem);
endmodule
