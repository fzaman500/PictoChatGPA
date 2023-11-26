timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module bluetooth_tx(
    input wire clk,
    input wire [7:0] tx_data,
    input wire rst_in,
    output tx
);

//data needs to be sampled at at least 921.6 KHz (115200 baud * 8) lsb first

parameter IDLE=3'b000, START=3'b001, DEVELOP=3'b010, STOP=3'b011, PARITY=3'b100;
logic [2:0] state;
logic [7:0] counter;
logic [1:0] in_out;

always_ff @( posedge clk ) begin : 
    if (rst_in) begin
        state <= IDLE;
        in_out <= 2'b00;
    end else begin
        if (state == IDLE) begin
            if (tx_data == 8'b1111_1111) begin //JUNK DATA
                tx <= 1; //keep high
            end else begin
                state <= START;
            end
        end else if (state == START) begin
            tx <= 0; //set low start bit
            state <= DEVELOP;
            counter <= 0;
            in_out[0] <= 0;
        end else if (state == DEVELOP) begin
            tx <= tx_data[counter];
            counter <= counter + 1;
            if (counter == 8'b1111_1111) begin
                state <= STOP;
            end
        end else if (state == STOP) begin
            state <= PARITY;
            tx <= 1; //end bit
            in_out[1] <= 1;
        end else if (state == PARITY) begin
            tx <= in_out[0] ^ in_out[1];
            STATE <= IDLE;
        end else begin //default IDLE
            STATE <= IDLE;
            tx <= 1;
        end
    end
end

endmodule
`default_nettype wire