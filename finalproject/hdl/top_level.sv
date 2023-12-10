`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level(
  input wire clk_100mhz,
  input wire [3:0] btn, //all four momentary button switches
  input wire ble_uart_tx,
  inout wire sda,
  output logic [7:0] pmoda, //output I/O used for SPI TX (in part 3)
  input wire [6:0] pmodb, //input I/O used for SPI RX (in part 3)
  input wire [15:0] sw, 
  input wire ble_uart_rts, //flipped, if computer ready request to send
  output logic ble_uart_cts, //flipped, if ready to give data from fpga, clear to send
  output logic ble_uart_rx,
  output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  output logic [6:0] ss1_c, //cathod controls for the segments of lower four digits
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1 //rgb led
  );

//BUTTON CLEANING
logic btn0_clean_old;
logic btn0_clean;
debouncer btn0_db(
  .clk_in(clk_100mhz),                
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

always_ff @(posedge clk_100mhz) begin
  btn0_clean_old <= btn0_clean;
  btn1_clean_old <= btn1_clean;
  btn2_clean_old <= btn2_clean;
end

logic sys_rst;
assign sys_rst = btn0;

/*
//I2C Module
logic [8:0] x_from_i2c;
logic [7:0] y_from_i2c;


//Processing Touch
logic [2:0] color;
logic ad;
process_touch process_touch_inst (
  .x(x_from_i2c),
  .y(y_from_i2c),
  .color(color),
  .active_draw(ad)
);
*/





//ALL OF THE BLUETOOTH
logic clean_ble_uart_tx;
synchronizer synchronizer_inst (
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .us_in(ble_uart_tx),
  .s_out(clean_ble_uart_tx)
);

logic bluetooth_clk_real;
baud_wiz_off_100 baud_clk_gen (
  .rst_in(sys_rst),
  .clk_in(clk_100mhz),
  .valid_out(bluetooth_clk_real)
);

//Transmitting
logic [7:0] packet;
logic [7:0] sending_fifo [2:0]; //this is 3 arrays of size 8 each right
logic [2:0] count_fifo;
always_ff @(posedge clk_100mhz) begin
  if (sys_rst) begin
    packet <= 8'b0000_0000;
    //tx_finished <= 0;
    count_fifo <= 0;
    sending_fifo[0] <= draw_col1;//8'h61;//
    sending_fifo[1] <= draw_row1[7:0];//8'h67;
    sending_fifo[2] <= 8'h0A; //from 0A
  end else begin
    if (tx_finished) begin
      if (count_fifo == 2) begin
        count_fifo <= 0;
      end else begin
        count_fifo <= count_fifo + 1;
      end
      sending_fifo[0] <= draw_col1;//draw_col1;//8'h61;//
      sending_fifo[1] <= draw_row1[7:0];//draw_row1[7:0];//8'h67;
      sending_fifo[2] <= 8'h0A; //from 0A
    end else begin
      packet <= sending_fifo[count_fifo];
    end
  end
end

//the number display
logic [6:0] ss_c; //used to grab output cathode signal for 7s leds
assign ss0_c = ss_c; //control upper four digit's cathodes!
assign ss1_c = ss_c; //same as above but for lower four digits!

logic [31:0] display_val;
seven_segment_controller seven_segment_controller_inst (
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .val_in(display_val),
  .cat_out(ss_c),
  .an_out({ss0_an, ss1_an})
);

//assign ble_uart_cts = 1;
logic tx_finished;
logic busy_tx;
bluetooth_tx bt_tx_inst (
  .clk(clk_100mhz),
  .baud_clk(bluetooth_clk_real),
  .tx_data(packet), //.tx_data(packet)
  .rst_in(sys_rst),
  .send_data_btn(btn1), //computer ready request to send
  .tx(ble_uart_rx), //flipped according to inst
  .finished_sending(tx_finished),
  .busy_out(busy_tx)
);

logic finished_receiving;
//Recieving
logic [7:0] data_out;
bluetooth_rx bt_rx_inst (
  .clk(clk_100mhz),
  .rx(clean_ble_uart_tx), //flipped according to inst
  .rst_in(sys_rst),
  .finished_receiving(finished_receiving),
  .data_out(data_out)
);

always_ff @(posedge clk_100mhz) begin
  if (sys_rst) begin
    display_val <= 32'hFEEDBEEF;
  end else if (finished_receiving) begin
    display_val <= {display_val[23:0], data_out};
  end 
end





//SPI DISPLAY STUFF
logic [7:0] draw_col1;
logic [7:0] draw_col2;
logic [8:0] draw_row1;
logic [8:0] draw_row2;
logic [2:0] draw_color;
logic valid_draw_data;
logic [4:0] state;
logic drawn_finished;

logic [7:0] real_draw_col1;
logic [8:0] real_draw_row1;
logic [7:0] col_fifo [1:0];
logic [8:0] row_fifo [1:0];
logic count_display_fifo;

always_ff @(posedge clk_100mhz) begin
  if (sys_rst) begin
    col_fifo[0] <= draw_col1;
    row_fifo[0] <= draw_row1;
    col_fifo[1] <= display_val[15:8];
    row_fifo[1] <= display_val[7:0];
    count_display_fifo <= 0;
    real_draw_col1 <= 0;
    real_draw_row1 <= 0;
  end else if (drawn_finished) begin
    count_display_fifo <= ~count_display_fifo;
    real_draw_col1 <= col_fifo[count_display_fifo];
    real_draw_row1 <= row_fifo[count_display_fifo];
    col_fifo[0] <= draw_col1;
    row_fifo[0] <= draw_row1;
    col_fifo[1] <= display_val[15:8];
    row_fifo[1] <= display_val[7:0];
  end
end
  
display screen
( .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .custom_in(btn3),
  
  .col1_in(real_draw_col1),//.col1_in(draw_col1),
  .col2_in(real_draw_col1),//.col2_in(draw_col2),
  .row1_in(real_draw_row1),//.row1_in(draw_row1),
  .row2_in(real_draw_row1),//.row2_in(draw_row2),
  .color_in(draw_color),
  .valid_in(valid_draw_data),
  
  .tft_sdo(), // input
  .tft_sck(pmoda[0]),
  .tft_sdi(pmoda[1]),
  .tft_dc(pmoda[3]),
  .tft_reset(pmoda[4]),
  .tft_cs(pmoda[2]),
  .drawn_finished(drawn_finished),
  
  .sw(sw),
  .state_out(state)
);

// TESTING CODE
 
always_ff @(posedge clk_100mhz) begin
  
  if (btn2) begin
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

endmodule // top_level
`default_nettype wire