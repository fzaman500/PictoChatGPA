`timescale 1ns / 1ps
`default_nettype none

module process_touch_tb();

  logic [8:0] x;
  logic [7:0] y;
  logic [2:0] col;
  logic ad;


  process_touch uut
          ( .x(x),
            .y(y),
            .color(col),
            .active_draw(ad)
          );

  //initial block...this is our test simulation
  initial begin
    $dumpfile("process_touch_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,process_touch_tb);
    $display("Starting Sim"); //print nice message at start
    #10;
    x = 200;
    y = 200;
    #10;
    x = 10;
    y = 10;
    #10
    x = 30;
    y = 30;
    #10
    x = 35;
    y = 80;
    #10
    x = 35;
    y = 120;
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire