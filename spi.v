
module spi(
	input wire clk,

	input wire sck, cs, mosi,
	output wire miso,

	output reg rx_done,
	output reg [7:0] rx,
	output reg [7:0] rx_cnt,

	output wire tx_start,
	input wire [7:0] tx,
);

reg [2:0] bitcnt;
reg [7:0] tx_buf;


reg [2:0] sckr, csr;
reg [1:0] mosir;

// sck detection
always @(posedge clk) sckr <= {sckr[1:0], sck};
wire sck_rising = (sckr[2:1] == 2'b01);
wire sck_falling = (sckr[2:1] == 2'b10);

// cs detection
always @(posedge clk) csr <= {csr[1:0], cs};
wire cs_active = !csr[1];
wire cs_falling = (csr[2:1] == 2'b10);
wire cs_rising = (csr[2:1] == 2'b01);

// mosi detection
always @(posedge clk) mosir <= {mosir[0], mosi};
wire mosi_data = mosir[1];

reg [7:0] rx_byte_ctr;

always @(posedge clk) begin
	if (~cs_active) begin
		bitcnt <= 3'b000;
		rx <= 8'h00;
	end
	else if (sck_rising) begin
		bitcnt <= bitcnt + 3'b001;
		rx <= { rx[6:0], mosi_data };
	end
end

always @(posedge clk) rx_done <= (cs_active && sck_rising && (bitcnt == 3'b111));

// Count number of bytes we've recieved in this transaction
always @(posedge clk) begin
	if (cs_active && cs_falling) rx_byte_ctr <= 0;
	if (sck_falling && bitcnt == 3'b111) rx_byte_ctr <= rx_byte_ctr + 8'b00000001;
end

always @(posedge clk) begin
	if (~cs_active)
		tx_buf <= 8'h00;
	else if (bitcnt == 3'b000)
		tx_buf <= tx;
	else if (sck_falling)
		tx_buf <= { tx_buf[6:0], 1'b0 };
end

assign tx_start = (cs_active && (bitcnt == 3'b000));
assign miso = tx_buf[7];
assign rx_cnt = rx_byte_ctr;

endmodule
