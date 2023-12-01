`timescale 1ns / 1ps
`default_nettype none

module rx_tb();

  logic clk_in;
  logic [7:0] data_out;
  logic rst_in;
  logic cts;
  logic rx;
  logic baud_clk;
  logic finished_receiving;

  bluetooth_rx uut
          ( .clk(clk_in),
            .baud_clk(baud_clk),
            .data_out(data_out),
            .rst_in(rst_in),
            .cts(cts),
            .rx(rx),
            .finished_receiving(finished_receiving)
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("rx_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,rx_tb);
    $display("Starting Sim"); //print nice message at start
    baud_clk = 1;
    clk_in = 0;
    rst_in = 0;
    rx = 1;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #110
    rx = 0; //start
    #10
    rx = 1; //8'b1010_1011;
    #10
    rx = 1;
    #10
    rx = 0;
    #10
    rx = 1;
    #10
    rx = 0;
    #10
    rx = 1;
    #10
    rx = 0;
    #10
    rx = 1;
    #10
    rx = 1; //stop
    #10
    rx = ^(8'b1010_1011);
    #10
    rx = 1;
    #1000
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire