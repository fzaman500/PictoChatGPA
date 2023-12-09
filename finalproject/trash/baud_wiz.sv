`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module baud_wiz (
    input wire clk_in,
    input wire rst_in,
    output logic clk_out
);
logic [5:0] counter;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        counter <= 0;
        clk_out <= 0;
    end else if (counter == 49) begin
        counter <= 0;
        clk_out <= ~clk_out;
    end else begin
        counter <= counter + 1;
    end
end

endmodule
`default_nettype wire