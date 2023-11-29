`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level(
  input wire clk_100mhz,
  input wire [3:0] btn, //all four momentary button switches
  input wire ble_uart_tx,
  input wire [15:0] sw, 
  input wire ble_uart_rts, //flipped, if computer ready
  output logic ble_uart_cts, //flipped, if ready to give data from fpga
  output logic ble_uart_rx
  );

logic sys_rst;
assign sys_rst = btn[0];

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

//Setting bluetooth clock
logic bluetooth_clk;
baud_clk baud_inst (
  .clk(clk_in),
  .enable(1),
  .rst_in(sys_rst),
  .tick(bluetooth_clk)
);

//Packet Encoder
//GENERAL QUESTION HOW DO I DISTINGUISH SENDING PACKETS WITHOUT CLK ISSUES
logic [7:0] packet;
pkt_enc pkt_enc_inst_y (
  .x(),
  .y(),
  .color(color),
  .active_draw(ad),
  .pkt_num(0),
  .pkt(packet)
);

//Transmitting
bluetooth_tx bt_tx_inst (
  .clk(bluetooth_clk),
  .tx_data(packet),
  .rst_in(sys_rst),
  .tx(ble_uart_rx) //flipped according to inst
);

//Recieving
logic [7:0] data_out;
bluetooth_rx bt_rx_inst (
  .clk(bluetooth_clk),
  .rx(ble_uart_tx), //flipped according to inst
  .rst_in(sys_rst),
  .data_out(data_out)
);

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





endmodule // top_level
`default_nettype wire