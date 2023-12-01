`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module baud_wiz_off_100 (
    input wire clk_in,
    input wire rst_in,
    output logic valid_out
);
parameter cycle = 100_000_000 / (115_200 * 8);
logic [$clog2(cycle) + 1 : 0] counter;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        counter <= 0;
        valid_out <= 0;
    end else if (cycle == counter) begin
        counter <= 0;
        valid_out <= 1;
    end else begin
        counter <= counter + 1;
        valid_out <= 1;
    end
end

endmodule
`default_nettype wire