`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module bluetooth_rx(
    input wire clk,
    input wire baud_clk,
    input wire rx,
    input wire rst_in,
    output logic [7:0] data_out,
    output logic finished_receiving
);

//data needs to be sampled at at least 921.6 KHz (115200 baud * 8) lsb first

parameter IDLE=3'b000, START=3'b001, DEVELOP=3'b010, STOP=3'b011, PARITY=3'b100;
logic [2:0] state;
logic [7:0] counter;
logic [7:0] curr_data;

always_ff @( posedge clk ) begin 
    if (rst_in) begin
        state <= IDLE;
        finished_receiving <= 0;
        counter <= 0;
    end else if (baud_clk) begin
        if (state == IDLE) begin
            if (rx == 0) begin
                state <= DEVELOP;
            end
            finished_receiving <= 0;
        end else if (state == DEVELOP) begin
            counter <= counter + 1;
            if (counter == 8'b0000_1000) begin
                state <= PARITY;
            end
            curr_data <= {curr_data[6:0], rx};
        end else if (state == STOP) begin
            state <= IDLE;
        end else if (state == PARITY) begin
            if (rx == ^curr_data) begin
                data_out <= curr_data;
            end
            state <= STOP;
            finished_receiving <= 1;
        end else begin //default IDLE
            state <= IDLE;
        end
    end
end

endmodule
`default_nettype wire