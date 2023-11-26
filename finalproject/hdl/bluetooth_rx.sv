timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module bluetooth_rx(
    input wire clk,
    input wire rx,
    input wire rst_in,
    output [7:0] data_out
);

//data needs to be sampled at at least 921.6 KHz (115200 baud * 8) lsb first

parameter IDLE=3'b000, START=3'b001, DEVELOP=3'b010, STOP=3'b011, PARITY=3'b100;
logic [2:0] state;
logic [7:0] counter;
logic [7:0] curr_data;

always_ff @( posedge clk ) begin : 
    if (rst_in) begin
        state <= IDLE;
        in_out <= 2'b00;
    end else begin
        if (state == IDLE) begin
            if (rx == 0) begin
                state <= DEVELOP;
            end
        end else if (state == DEVELOP) begin
            tx <= tx_data[counter];
            counter <= counter + 1;
            if (counter == 8'b1111_1111) begin
                state <= STOP;
            end
        end else if (state == STOP) begin
            state <= PARITY;
        end else if (state == PARITY) begin
            if (rx && (curr_data != 8'b1111_1111)) begin
                data_out <= curr_data;
            end
            STATE <= IDLE;
        end else begin //default IDLE
            STATE <= IDLE;
        end
    end
end

endmodule
`default_nettype wire