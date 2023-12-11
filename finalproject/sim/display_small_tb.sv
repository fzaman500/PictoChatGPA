`timescale 1ns / 1ps
`default_nettype none

module display_tb();
  logic clk_in;
  logic rst_in;

	logic [7:0] draw_col1;
	logic [7:0] draw_col2;
  logic [8:0] draw_row1;
  logic [8:0] draw_row2;
  logic [2:0] draw_color;
  logic valid_draw_data;
  logic rst_out;
  logic [7:0] curr_color;
  logic size;

  logic data_out, data_clk_out, cs_out, dc_out;

  display screen
        ( .clk_in(clk_in),
          .rst_in(rst_in),
          .col1_in(draw_col1),
          .col2_in(draw_col2),
          .row1_in(draw_row1),
          .row2_in(draw_row2),
          .color_in(draw_color),
          .valid_in(valid_draw_data),
          
          .curr_color(curr_color),
          .size(size),

          .tft_sdo(), // input
          .tft_sck(data_clk_out),
          .tft_sdi(data_out),
          .tft_dc(dc_out),
          .tft_reset(rst_out),
          .tft_cs(cs_out)
        );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("display_small.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,display_tb);
    $display("Starting Sim"); //print nice message at start
    clk_in = 0;
    rst_in = 0;
    //data_in = 16'hBEEF; //16 long message, 2-wide bit duration
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    size = 0;
    curr_color = 8'h00;
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
    #6000000
    
	  draw_col1 = 100;
	  draw_col2 = 150;
    draw_row1 = 200;
    draw_row2 = 250;
    draw_color = 0;
    valid_draw_data = 1;
    #10
    valid_draw_data = 0;
    
    #200000
    
    $display("Finishing Sim"); //print nice message at end
    $finish;
  end
endmodule
`default_nettype wire
