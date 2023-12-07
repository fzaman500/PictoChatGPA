`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
//don't worry about weird edge cases
//we want a clean 50% duty cycle clock signal
module i2c
       #(   parameter DATA_WIDTH = 8,
            parameter DATA_PERIOD = 1000
        )
        ( input wire clk_in,
          input wire rst_in,
          input wire [DATA_WIDTH-1:0] address_in,
          input wire [DATA_WIDTH-1:0] data_in,
          input wire trigger_in,
          
          output logic [DATA_WIDTH-1:0] data_out,
          output logic valid_data,
          
          output logic i2c_clk, // clock
          inout wire i2c_sda // data
        );

  typedef enum { IDLE=0, START=4, END=5, ADDRESS=1, ASK_DATA=2, RECEIVE_DATA=3} i2c_state;  
  i2c_state state;
  

  logic sda_val;
  assign i2c_sda = sda_val ? 1'bz : 1'b0;

  logic [$clog2(DATA_PERIOD)-1:0] HALF_PERIOD; // 50%
  assign HALF_PERIOD = DATA_PERIOD/2;
  
  logic [$clog2(DATA_PERIOD):0] FULL_PERIOD; // 100%
  assign FULL_PERIOD = HALF_PERIOD*2;
  
    logic [$clog2(DATA_PERIOD):0] WRITE_PERIOD; // 25%
  assign WRITE_PERIOD = HALF_PERIOD/2;
  
  logic [$clog2(DATA_PERIOD):0] READ_PERIOD; // 75%
  assign READ_PERIOD = HALF_PERIOD + WRITE_PERIOD;
  
  
  logic [$clog2(DATA_PERIOD):0] period_counter;
  
  logic [DATA_WIDTH:0] address;
  logic [DATA_WIDTH:0] data;
  logic [DATA_WIDTH:0] sending_i;
  
  logic ack_p = 0; // ack primary (if 1, the fpga should send a 1)
  logic ack_s = 0; // ack secondary (if 1, the fpga should receive a 0)
  
  always_ff @(posedge clk_in) begin
  
    if (rst_in) begin
      // grab data and initialize vars
      state <= IDLE;
      period_counter <= 0;
      i2c_clk <= 1;
      sda_val <= 1;
    end
    else if (ack_p) begin
      if (period_counter == WRITE_PERIOD-1) begin
        sda_val <= 1;
        ack_p <= 0;
      end
    end
    else if (ack_s) begin
      if (period_counter == READ_PERIOD-1) begin
//        if (i2c_sda != 0) state <= IDLE; // if not ack, idle
        ack_s <= 0;
        ack_p <= 1;
      end
    end
    else begin
    
      case (state)
        
        IDLE: begin
          if (trigger_in) begin
            sda_val <= address_in[sending_i];
            address <= address_in;
            data <= data_in;
            
            state <= START;
            sda_val <= 1;
          end
        end
        
        START: begin
        
          if (period_counter == WRITE_PERIOD-1) begin
            sda_val <= 0;
            state <= ADDRESS;
            sending_i <= DATA_WIDTH;
          end
          
        end
        
        ADDRESS: begin
        
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // address is fully transmitted
              ack_s <= 1;
              state <= ASK_DATA;
              sending_i <= DATA_WIDTH;
            end else begin
              // go to next index of address
              sda_val <= address[sending_i-1]; // transmit next piece of address
              sending_i <= sending_i - 1;
            end
          end
        end
        ASK_DATA: begin
        
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // data is fully transmitted
              ack_s <= 1;
              state <= RECEIVE_DATA;
              sending_i <= DATA_WIDTH;
            end else begin
              // go to next index of data
              sda_val <= data[sending_i-1]; // transmit next piece of data
              sending_i <= sending_i - 1;
            end
          end
          
        end
        
        RECEIVE_DATA: begin
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // data is fully received
              valid_data <= 0;
              ack_p <= 1;
              sending_i <= 2;
              state <= IDLE;
            end else begin
              // go to next index of data
              data_out[sending_i-1] <= sda_val; // transmit next piece of data
              sending_i <= sending_i - 1;
              
              if (sending_i == 1) begin
                valid_data <= 1;
              end
            end
          end
        end
        
        END: begin
        
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // address is fully transmitted
              state <= IDLE;
              sending_i <= DATA_WIDTH - 1;
            end
            else if (sending_i == 2) begin
              sda_val <= 1; // transmit next piece of address
              sending_i <= sending_i - 1;
            end
            else if (sending_i == 1) begin
              i2c_clk <= 1; // transmit next piece of address
              sending_i <= sending_i - 1;
            end
          end
          
        end
        
      endcase
    end
    
    if (state != IDLE) begin
        // update period_counter
        if (period_counter == FULL_PERIOD-1) begin
          i2c_clk <= 0;
          period_counter <= 0;
        end else begin
          period_counter <= period_counter + 1;
        end
        
        if (period_counter == HALF_PERIOD-1) begin
          i2c_clk <= 1;
        end
      end
  end

endmodule
`default_nettype wire // prevents system from inferring an undeclared logic (good practice)

