`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module pkt_enc(
    input wire [7:0] pkt,
    output [7:0] y,
    output [7:0] x,
    output wire [2:0] color

);

//IDEA I USE OVERFLOW LOGIC AND CHECK IF PKT EQUAL TO OLD PKT



endmodule
`default_nettype wire