`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module touchscreen
       #(   
            parameter NUM_COLS = 240,
            parameter NUM_ROWS = 320
        )
        ( input wire clk_in,
          input wire rst_in,
          
          input wire i2c_irq, // interrupt, active low
          inout wire i2c_sda, // data
          output logic i2c_clk, // clock
          
          output logic valid_out,
          output logic [11:0] x_out,
          output logic [11:0] y_out
        );

  typedef enum { IDLE=0, GET_X=3, GET_Y=4} touch_state;
  
  touch_state state;
  
  logic [7:0] data_in;
  logic [7:0] address_in;
  logic trigger_in;
  
  logic [7:0] data_out;
  logic valid_data;
  
  logic waiting;
  
  i2c i2c_comm
        ( .clk_in(clk_in),
          .rst_in(rst_in),
          .address_in(address_in),
          .data_in(data_in),
          .trigger_in(trigger_in),
          
          .data_out(data_out),
          .valid_data(valid_data),
          
          .i2c_clk(i2c_clk), // clock
          .i2c_sda(i2c_sda) // data
        );
  
  
  always_ff @(posedge clk_in) begin
  
    if (rst_in) begin
      state <= IDLE;
      waiting = 0;
    end
    else begin
      // BEGIN STATE MACHINE //
      
      case (state)
        IDLE: begin
          waiting = 0;
          trigger_in <= 0;
        
          if (i2c_irq == 0) begin // if touch (active low)
            state <= GET_X;
          end
        end
        GET_X: begin
          if (!waiting) begin
            address_in <= { 7'b0111000, 1'b1 }; // address + read/write
            data_in <= { 8'h89 }; // TESTING
            trigger_in <= 1;
            waiting = 1;
          end
          else begin
            trigger_in <= 0;
          end
        
          if (valid_data) begin
            waiting = 0;
            state <= IDLE;
          end
        end
      
      endcase
      
    end
  end

endmodule
`default_nettype wire // prevents system from inferring an undeclared logic (good practice)

