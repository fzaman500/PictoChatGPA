`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
	 
module top_level(
  input wire clk_100mhz, //
  input wire [3:0] btn, //all four momentary button switches
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  inout wire sda,
  output logic [7:0] pmoda, //output I/O used for SPI TX (in part 3)
  input wire [6:0] pmodb, //input I/O used for SPI RX (in part 3)
  input wire [15:0] sw
  );
  
  //assign rgb1= 0;
  //assign rgb0 = 0;
  logic btn0_clean_old;
  logic btn0_clean;
  debouncer btn0_db(.clk_in(clk_100mhz),
                  .rst_in(sys_rst),
                  .dirty_in(btn[0]),
                  .clean_out(btn0_clean));
  
  logic btn1_clean_old;
  logic btn1_clean;
  debouncer btn1_db(.clk_in(clk_100mhz),
                  .rst_in(sys_rst),
                  .dirty_in(btn[1]),
                  .clean_out(btn1_clean));
                  
  logic btn2_clean_old;
  logic btn2_clean;
  debouncer btn2_db(.clk_in(clk_100mhz),
                  .rst_in(sys_rst),
                  .dirty_in(btn[2]),
                  .clean_out(btn2_clean));
                  
  logic btn3_clean_old;
  logic btn3_clean;
  debouncer btn3_db(.clk_in(clk_100mhz),
                  .rst_in(sys_rst),
                  .dirty_in(btn[3]),
                  .clean_out(btn3_clean));
  
  logic btn0;
  logic btn1;
  logic btn2;
  logic btn3;
  
  assign btn0 = btn0_clean && !btn0_clean_old;
  assign btn1 = btn1_clean && !btn1_clean_old;
  assign btn2 = btn2_clean && !btn2_clean_old;
  assign btn3 = btn3_clean && !btn3_clean_old;
//  assign btn0 = btn0_clean;
//  assign btn1 = btn1_clean;
//  assign btn2 = btn2_clean;
  
  
  always_ff @(posedge clk_100mhz) begin
    btn0_clean_old <= btn0_clean;
    btn1_clean_old <= btn1_clean;
    btn2_clean_old <= btn2_clean;
  end
  
  logic sys_rst;
  assign sys_rst = btn0;
 

  logic valid_touch_out;
  logic [11:0] x_out;
  logic [11:0] y_out;

  touchscreen touch
        ( .clk_in(clk_100mhz),
          .rst_in(sys_rst),
          
          .i2c_irq(pmodb[6]), // interrupt, active low
          .i2c_sda(sda), // data
          .i2c_clk(pmoda[7]), // clock
          
          .valid_out(valid_touch_out),
          .x_out(x_out),
          .y_out(y_out)
        );


  /*
  logic [7:0] draw_col1;
  logic [7:0] draw_col2;
  logic [8:0] draw_row1;
  logic [8:0] draw_row2;
  logic [2:0] draw_color;
  logic valid_draw_data;
 
  logic [4:0] state;
  
  display screen
       ( .clk_in(clk_100mhz),
         .rst_in(sys_rst),
         .custom_in(btn2),
         
         .col1_in(draw_col1),
         .col2_in(draw_col2),
         .row1_in(draw_row1),
         .row2_in(draw_row2),
         .color_in(draw_color),
         .valid_in(valid_draw_data),
         
         .tft_sdo(), // input
         .tft_sck(pmoda[0]),
         .tft_sdi(pmoda[1]),
         .tft_dc(pmoda[3]),
         .tft_reset(pmoda[4]),
         .tft_cs(pmoda[2]),
         
         .sw(sw),
         .state_out(state)
       );
       
  // TESTING CODE
 
  always_ff @(posedge clk_100mhz) begin
    
    if (btn1) begin
      draw_col1 <= sw[15:9];
      draw_col2 <= sw[15:9];
      draw_row1 <= sw[8:0];
      draw_row2 <= sw[8:0];
      draw_color <= 0;
      valid_draw_data <= 1;
    end
    else begin
      valid_draw_data <= 0;
    end
  end
 */
 
endmodule // top_level
`default_nettype wire
