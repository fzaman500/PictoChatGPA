`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module pkt_enc(
    input wire [8:0] x,
    input wire [7:0] y,
    input wire [2:0] color,
    input wire active_draw, 
    input wire pkt_num
    output [7:0] pkt
);

always_comb begin
    if (active_draw) begin
        if (pkt_num) begin
            pkt = {x[8], color, 4'b0000};
        end else begin
            pkt = y;
        end
    end
end

endmodule
`default_nettype wire