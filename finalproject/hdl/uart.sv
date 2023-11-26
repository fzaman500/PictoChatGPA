timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module uart(
    input wire uart_txd,
    output wire uart_rxd
);
endmodule



//uart rx
module uart_rx (
    input wire clk,

    input wire rx,

    output reg [7:0] data_o,
    output reg valid_o);

    parameter CLOCKS_PER_BAUD = 0;
    localparam IDLE = 0;
    localparam BIT_ZERO = 1;
    localparam STOP_BIT = 9;

    reg	[3:0] state = IDLE;
    reg	[15:0] baud_counter = 0;
    reg zero_baud_counter;
    assign zero_baud_counter = (baud_counter == 0);

    // 2FF Synchronizer
    reg ck_uart = 1;
    reg	q_uart = 1;
    always @(posedge clk)
        { ck_uart, q_uart } <= { q_uart, rx };

    always @(posedge clk)
        if (state == IDLE) begin
            state <= IDLE;
            baud_counter <= 0;
            if (!ck_uart) begin
                state <= BIT_ZERO;
                baud_counter <= CLOCKS_PER_BAUD+CLOCKS_PER_BAUD/2-1'b1;
            end
        end

        else if (zero_baud_counter) begin
            state <= state + 1;
            baud_counter <= CLOCKS_PER_BAUD-1'b1;
            if (state == STOP_BIT) begin
                state <= IDLE;
                baud_counter <= 0;
            end
        end

        else baud_counter <= baud_counter - 1'b1;

    always @(posedge clk)
        if ( (zero_baud_counter) && (state != STOP_BIT) )
            data_o <= {ck_uart, data_o[7:1]};

    initial	valid_o = 1'b0;
    always @(posedge clk)
        valid_o <= ( (zero_baud_counter) && (state == STOP_BIT) );

endmodule


//TX
module uart_tx (
	input wire clk,

	input wire [7:0] data_i,
	input wire start_i,
	output reg done_o,

	output reg tx);

	// this module supports only 8N1 serial at a configurable baudrate
	parameter CLOCKS_PER_BAUD = 0;
	reg [$clog2(CLOCKS_PER_BAUD)-1:0] baud_counter = 0;

	reg [8:0] buffer = 0;
	reg [3:0] bit_index = 0;

	initial done_o = 1;
	initial tx = 1;

	always @(posedge clk) begin
		if (start_i && done_o) begin
			baud_counter <= CLOCKS_PER_BAUD - 1;
			buffer <= {1'b1, data_i};
			bit_index <= 0;
			done_o <= 0;
			tx <= 0;
		end

		else if (!done_o) begin
			baud_counter <= baud_counter - 1;
			done_o <= (baud_counter == 1) && (bit_index == 9);

			// a baud period has elapsed
			if (baud_counter == 0) begin
				baud_counter <= CLOCKS_PER_BAUD - 1;

				// clock out another bit if there are any left
				if (bit_index < 9) begin
					tx <= buffer[bit_index];
					bit_index <= bit_index + 1;
				end

				// byte has been sent, send out next one or go to idle
				else begin
					if(start_i) begin
						buffer <= {1'b1, data_i};
						bit_index <= 0;
						tx <= 0;
					end

					else done_o <= 1;
				end
			end
		end
	end
endmodule

`default_nettype wire