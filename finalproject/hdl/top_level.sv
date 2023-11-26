`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level(
  input wire clk_100mhz,
  input wire [3:0] btn, //all four momentary button switches
  input wire ble_uart_tx,
  input wire ble_uart_rts, //flipped, if computer ready
  output logic ble_uart_cts, //flipped, if ready to give data from fpga
  output logic ble_uart_rx
  );


endmodule // top_level
`default_nettype wire