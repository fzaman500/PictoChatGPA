`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module bluetooth_tx(
    input wire clk,
    input wire [7:0] tx_data,
    input wire rst_in,
    input wire send_data_btn,
    input wire baud_clk,
    output logic tx,
    output logic finished_sending
);

//data needs to be sampled at at least 921.6 KHz (115200 baud * 8) lsb first

parameter IDLE=3'b000, START=3'b001, DEVELOP=3'b010, STOP=3'b011, PARITY=3'b100;
logic [2:0] state;
logic [7:0] counter;

always_ff @( posedge clk ) begin 
    if (rst_in) begin
        state <= IDLE;
        finished_sending <= 0;
        tx <= 1;
    end else if (baud_clk) begin
        if (state == IDLE) begin
            if (send_data_btn) begin
                state <= START;
            end else begin
                tx <= 1;
            end
            finished_sending <= 0;
        end else if (state == START) begin
            tx <= 0; //set low start bit
            state <= DEVELOP;
            counter <= 0;
        end else if (state == DEVELOP) begin
            if (counter == 8'b0000_0111) begin
                state <= STOP;
                tx <= tx_data[counter];
            end else begin
                tx <= tx_data[counter];
                counter <= counter + 1;
            end
        end else if (state == STOP) begin
            state <= IDLE;
            tx <= 1; //end bit
            finished_sending <= 1;
        end else if (state == PARITY) begin
            tx <= 1; //just trying this
            state <= STOP;
        end else begin //default IDLE
            state <= IDLE;
            tx <= 1;
        end
    end else begin
        finished_sending <= 0;
    end
end

endmodule
`default_nettype wire