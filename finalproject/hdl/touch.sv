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
          output logic [7:0] x_out,
          output logic [8:0] y_out,
          
          output logic [7:0] touch_out,
          input wire [15:0] sw
        );

  typedef enum { IDLE=0, GET_X=1, GET_Y=2, GET_Y2=3} touch_state;
  
  touch_state state;
  
  logic [6:0] ADDRESS;
  
  logic [7:0] data_in;
  logic trigger_in;
  
  logic [7:0] data_out;
  logic valid_data;
  
  i2c i2c_comm
        ( .clk_in(clk_in),
          .rst_in(rst_in),
          .data_in(data_in),
          .trigger_in(trigger_in),
          
          .ADDRESS(ADDRESS),
          
          .data_out(data_out),
          .valid_data(valid_data),
          
          .i2c_clk(i2c_clk), // clock
          .i2c_sda(i2c_sda) // data
        );
  
  logic [7:0] x_touch;
  logic [8:0] y_touch;
  
  always_ff @(posedge clk_in) begin
  
    if (rst_in) begin
      state <= IDLE;
      touch_out <= 0;
      valid_out <= 0;
    end
    else begin
      // BEGIN STATE MACHINE //
      
      case (state)
        IDLE: begin
          valid_out <= 0;
          touch_out <= 0;
          trigger_in <= 0;
        
          if (i2c_irq == 0) begin // if touch (active low)
            data_in <= 8'h04; // TESTING
            ADDRESS <= 7'h38;
            trigger_in <= 1;
            state <= GET_X;
          end
          
        end
        GET_X: begin
          trigger_in <= 0;
        
          if (valid_data) begin
            // store data
            touch_out <= data_out;
            x_out <= data_out;
            
            // send next data
            data_in <= 8'h06; // TESTING
            ADDRESS <= 7'h38;
            trigger_in <= 1;
            state <= GET_Y;
          end
        end
        GET_Y: begin
          trigger_in <= 0;
        
          if (valid_data) begin
            // store data
            touch_out <= data_out;
            y_out[7:0] <= data_out;
            
            // send next data
            data_in <= 8'h05; // TESTING
            ADDRESS <= 7'h38;
            trigger_in <= 1;
            state <= GET_Y2;
          end
        end
        GET_Y2: begin
          trigger_in <= 0;
        
          if (valid_data) begin
            // store data
            touch_out <= data_out;
            y_out[8] <= data_out[0];
            
            // end sequence
            valid_out <= 1;
            state <= IDLE;
          end
        end
      endcase
      
    end
  end

endmodule
`default_nettype wire // prevents system from inferring an undeclared logic (good practice)

