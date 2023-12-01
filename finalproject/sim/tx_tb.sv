`timescale 1ns / 1ps
`default_nettype none

module tx_tb();

  logic clk_in;
  logic [7:0] tx_data;
  logic rst_in;
  logic send_data_btn;
  logic tx;
  logic baud_clk;
  logic finished_sending;


  bluetooth_tx uut
          ( .clk(clk_in),
            .baud_clk(baud_clk),
            .tx_data(tx_data),
            .rst_in(rst_in),
            .send_data_btn(send_data_btn),
            .tx(tx),
            .finished_sending(finished_sending)
          );

  always begin
      #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
      clk_in = !clk_in;
  end
  //initial block...this is our test simulation
  initial begin
    $dumpfile("tx_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0,tx_tb);
    $display("Starting Sim"); //print nice message at start
    baud_clk = 1;
    send_data_btn = 1;
    clk_in = 0;
    rst_in = 0;
    rts = 1;
    #10;
    rst_in = 1;
    #10;
    rst_in = 0;
    #100
    tx_data = 8'b1010_1011;
    #100000
    $display("Simulation finished");
    $finish;
  end
endmodule
`default_nettype wire