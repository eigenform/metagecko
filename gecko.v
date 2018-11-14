/* This is directly based on existing VHDL implementations of a USB Gecko.
 *
 * In particular, see these resources:
 *	https://wiibrew.org/w/images/1/16/USBGecko-svn-r17.tar.gz
 *	https://code.google.com/archive/p/geckodownloads/
 *	http://retro-system.com/comms.zip
 */

module gecko(
	input wire clk,

	input wire sck, cs, mosi,
	output wire miso,

	//output reg rx_done,
	//output reg [7:0] rx,
	//output reg [7:0] rx_cnt,
	//output wire tx_start,
	//input wire [7:0] tx,
);

reg [3:0] bitcnt;
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



reg [3:0] exi_count;
reg [3:0] exi_cmd;
reg [7:0] exi_read_buf;
reg [7:0] exi_usb_data_in;
reg [7:0] exi_usb_data_in;

reg led_state;
reg usb_tx;
reg usb_rd;
reg usb_wr;
reg usb_rx_status_set;
reg usb_tx_status_set;
reg usb_read_mode_set;
reg usb_write_mode_set;
reg id_mode_set;

// Reset state when CS isn't active
always @(posedge clk) if (~cs_active) begin
	exi_count <= 4'b0000;
	exi_cmd <= 0;
	exi_read_buf <= 0;
	exi_usb_data_in <= 0;
	miso <= 0;
	usb_rd <= 1;
	usb_wr <= 0;
	usb_tx_status_set <= 0;
	usb_rx_status_set <= 0;
	usb_read_mode_set <= 0;
	usb_write_mode_set <= 0;
	id_mode_set <= 0;
end

always @(posedge clk) if (cs_active && sck_rising) begin
	case (exi_count)

/* Read a 4-bit command from EXI input line.
 * Just shift back zeros to respond.  
 */

		4'b0000: begin
			exi_cmd[3] <= mosi_data;
			miso <= 0;
		end
		4'b0001: begin
			exi_cmd[2] <= mosi_data;
			miso <= 0;
		end
		4'b0010: begin
			exi_cmd[1] <= mosi_data;
			miso <= 0;
		end
		4'b0011: begin
			exi_cmd[0] = mosi_data;
			if (exi_cmd == 4'hA)
				miso <= 1;
		end

/* Start reading bits from EXI input line into a 8-bit buffer.
 * Set some state depending on the command recieved from the client.
 */

		4'b0100: begin
			exi_read_buf[7] <= mosi_data;

			if (usb_read_mode_set == 1)
				miso <= 0;

			// LED commands
			if (exi_cmd == 4'h7)
				led_state <= 1;
			if (exi_cmd == 4'h8)
				led_state <= 0;

			// Handle ID command, bit 0
			if (exi_cmd == 4'h9) begin
				id_mode_set <= 1;
				miso <= 1;
			end

			if (exi_cmd == 4'hB) begin
				if (usb_tx == 0) begin
					miso <= 1;
					usb_tx_status_set <= 1;
				end
			end
			if (exi_cmd == 4'hC) begin
				if (usb_tx == 0) begin
					miso <= 1;
					usb_tx_status_set <= 1;
				end
			end
			if (exi_cmd == 4'hD) begin
				if (usb_tx == 0) begin
					miso <= 1;
					usb_tx_status_set <= 1;
				end
			end
		end

/* If read mode is set, prepare the USB buffer with some data from the device. 
 * If ID mode is set, start shifting back the bits of the ID (0x0470).
 */
		4'b0101: begin
			exi_read_buf[6] <= mosi_data;
			if (usb_read_mode_set == 1)
				exi_usb_data_in[7:0] <= usb_data[7:0];

			// Handle ID command, bit 1
			if (id_mode_set == 1)
				miso <= 0;
			if ( (usb_write_mode_set == 1) || (usb_tx_status_set == 1) 
				|| (usb_rx_status_set == 1)) begin
					miso <= 0;
					usb_tx_status_set <= 0;
					usb_rx_status_set <= 0;
				end
		end

		4'b0110: begin
			exi_read_buf[5] <= mosi_data;
			if (usb_read_mode_set == 1)
				usb_rb <= 1;

			// Handle ID command, bit 2
			if (id_mode_set == 1)
				miso <= 0;
		end

// d. Start sending data back from the USB buffer here
		4'b0111: begin
			exi_read_buf[4] <= mosi_data;
			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[7];
			if (id_mode_set == 1)
				miso <= 0;
		end

		4'b1000: begin
			exi_read_buf[3] <= mosi_data;

			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[6];
			if (id_mode_set == 1)
				miso <= 1;
		end

		4'b1001: begin
			exi_read_buf[2] <= mosi_data;

			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[5];
			if (id_mode_set == 1)
				miso <= 1;
		end

		4'b1010: begin
			exi_read_buf[1] <= mosi_data;

			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[4];
			if (id_mode_set == 1)
				miso <= 1;
		end

		4'b1011: begin
			exi_read_buf[0] <= mosi_data;

			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[3];

			if (id_mode_set == 1) begin
				miso <= 0;
				id_mode_set <= 1;
			end
		end

// b. Stop reading input data into a buffer
		4'b1100: begin
			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[2];

			if (usb_write_mode_set == 1) begin
				usb_wr <= 1;
				usb_data[7:0] <= exi_read_buf[7:0];
			end
		end

		4'b1101: begin
			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[1];
		end

		4'b1110: begin
			if (usb_read_mode_set == 1)
				miso <= exi_usb_data_in[0];
			if (usb_write_mode_set == 1) begin
				usb_wr <= 0;
				usb_data[7:0] <= 8'h00;
				usb_write_mode_set <= 0;
			end
		end
	endcase

	// Always increment the bit counter 
	exi_count <= exi_count + 4'b0001;
end

endmodule
