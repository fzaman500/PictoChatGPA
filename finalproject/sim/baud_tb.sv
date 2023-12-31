`timescale 1ns / 1ps
`default_nettype none

module baud_tb();

  logic clk_in;
  logic rst_in;
  logic bluetooth_clk;


  baud_clk uut
          ( .clk(clk_in),
            .enable(1),
            .rst_in(rst_in),
            .tick(bluetooth_clk)
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("baud_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,baud_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #100000
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire