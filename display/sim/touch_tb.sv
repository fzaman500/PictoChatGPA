`timescale 1ns / 1ps
`default_nettype none

module touch_tb();
  logic clk_in;
  logic rst_in;
  logic i2c_irq;
  logic i2c_sda;
  logic i2c_clk;
  logic valid_out;
  logic [11:0] x_out;
  logic [11:0] y_out;

  touchscreen touch
        ( .clk_in(clk_in),
          .rst_in(rst_in),
          
          .i2c_irq(i2c_irq), // interrupt, active low
          .i2c_sda(i2c_sda), // data
          .i2c_clk(i2c_clk), // clock
          
          .valid_out(valid_out),
          .x_out(x_out),
          .y_out(y_out)
        );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("touch.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,touch_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    //data_in = 16'hBEEF; //16 long message, 2-wide bit duration
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #50;
    i2c_irq = 0;
    #10;
    i2c_irq = 1;
    #50;
/*    $display("data_in = %16b ",data_in);
    $display("trig data clk");
    for(int i=0; i<300; i=i+1)begin
      $display("%b     %b    %b",trigger_in, data_out, data_clk_out);
      #10;
    end
    data_in = 16'hFEED;
    trigger_in = 1;
    #10;
    trigger_in = 0;
    $display("trig data clk");
    for(int i=0; i<300; i=i+1)begin
      $display("%b   %b    %b",trigger_in, data_out, data_clk_out);
      #10;
    end*/
    
    #2000000
    
    $display("Finishing Sim"); //print nice message at end
    $finish;
  end
endmodule
`default_nettype wire
