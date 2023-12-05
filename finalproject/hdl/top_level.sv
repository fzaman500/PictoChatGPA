`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level(
  input wire clk_100mhz,
  input wire [3:0] btn, //all four momentary button switches
  input wire ble_uart_tx,
  input wire [15:0] sw, 
  input wire ble_uart_rts, //flipped, if computer ready request to send
  output logic ble_uart_cts, //flipped, if ready to give data from fpga, clear to send
  output logic ble_uart_rx,
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [3:0] ss0_an,//anode control for upper four digits of seven-seg display
  output logic [3:0] ss1_an,//anode control for lower four digits of seven-seg display
  output logic [6:0] ss0_c, //cathode controls for the segments of upper four digits
  output logic [6:0] ss1_c //cathod controls for the segments of lower four digits
  );

logic [6:0] ss_c; //used to grab output cathode signal for 7s leds
assign ss0_c = ss_c; //control upper four digit's cathodes!
assign ss1_c = ss_c; //same as above but for lower four digits!

logic sys_rst;
assign sys_rst = btn[0];

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
//Setting bluetooth clock
//logic bluetooth_clk_int;
/*baud_clk baud_inst (
  .clk(clk_100mhz),
  .enable(1),
  .rst_in(sys_rst),
  .tick(bluetooth_clk)
);*/

/*clk_wiz_0 clk_115 (
  .reset(sys_rst),
  .clk_in1(clk_100mhz),
  .clk_out1(bluetooth_clk_int),
  .locked()
);


baud_wiz baud_gen (
  .rst_in(sys_rst),
  .clk_in(bluetooth_clk_int),
  .clk_out(bluetooth_clk_real)
);*/

logic clean_btn1;
debouncer debouncer_inst (
  .clk_in(clk_100mhz),
  .rst_in(sys_rst),
  .dirty_in(btn[1]),
  .clean_out(clean_btn1)
);

logic bluetooth_clk_real;
baud_wiz_off_100 baud_clk_gen (
  .rst_in(sys_rst),
  .clk_in(clk_100mhz),
  .valid_out(bluetooth_clk_real)
);

//Transmitting
logic [7:0] packet;

/*
logic [3:0] sending_fifo [7:0]; //this is 4 arrays of size 8 each right
logic [1:0] count_fifo;
always_ff @(posedge clk_100mhz) begin
  if (rst_in) begin
    packet <= 8'b0000_1010;
    count_fifo <= 0;
    sending_fifo[0] <= y;
    sending_fifo[1] <= x[7:0];
    sending_fifo[2] <= {x[8], color, 4'b0000};
    sending_fifo[3] <= 8'b0000_1010;
  end else if (rts) begin
    if (tx_finished) begin
      count_fifo <= count_fifo + 1;
      if (count_fifo ==  3) begin
        sending_fifo[0] <= y;
        sending_fifo[1] <= x[7:0];
        sending_fifo[2] <= {x[8], color, 4'b0000};
        sending_fifo[3] <= 8'b0000_1010;
      end
    end
    packet <= sending_fifo[count_fifo];
  end
end
*/

logic [7:0] sending_fifo [3:0]; //this is 2 arrays of size 8 each right
logic [2:0] count_fifo;
always_ff @(posedge clk_100mhz) begin
  if (sys_rst) begin
    packet <= 8'b0000_0000;
    //tx_finished <= 0;
    count_fifo <= 0;
    sending_fifo[0] <= 8'h56;
    sending_fifo[1] <= 8'h61;
    sending_fifo[2] <= 8'h21;
    sending_fifo[3] <= 8'h0A; //from 0A
  end else begin
    if (tx_finished) begin
      if (count_fifo == 3) begin
        count_fifo <= 0;
      end else begin
        count_fifo <= count_fifo + 1;
      end
      sending_fifo[0] <= 8'h56;
      sending_fifo[1] <= 8'h61;
      sending_fifo[2] <= 8'h21;
      sending_fifo[3] <= 8'h0A; //from 0A
  end else begin
    packet <= sending_fifo[count_fifo];
  end
  end
end

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
bluetooth_tx bt_tx_inst (
  .clk(clk_100mhz),
  .baud_clk(bluetooth_clk_real),
  .tx_data(packet), //.tx_data(packet)
  .rst_in(sys_rst),
  .send_data_btn(clean_btn1), //computer ready request to send
  .tx(ble_uart_rx), //flipped according to inst
  .finished_sending(tx_finished)
);


logic finished_receiving;
//Recieving
logic [7:0] data_out;
bluetooth_rx bt_rx_inst (
  .clk(clk_100mhz),
  .baud_clk(bluetooth_clk_real),
  .rx(ble_uart_tx), //flipped according to inst
  .rst_in(sys_rst),
  .finished_receiving(finished_receiving),
  .data_out(data_out)
);

always_ff @(posedge clk_100mhz) begin
  if (sys_rst) begin
    display_val <= 32'hFEEDBEEF;
  end else if (finished_receiving) begin
    display_val <= data_out;
  end 
end

/*
always_comb begin
  if (finished_receiving) begin
    rgb1= 0;
  end else begin
    rgb0= 1;
  end
end
*/

/*
//Packet Decoder
logic [8:0] x_to_spi;
logic [7:0] y_to_spi;
logic [2:0] color_to_spi;
pkt_dec pkt_dec_inst (
  .pkt(data_out),
  .y(),
  .x(),
  .color()
);
*/

endmodule // top_level
`default_nettype wire