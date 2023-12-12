`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
//don't worry about weird edge cases
//we want a clean 50% duty cycle clock signal
module i2c
       #(   parameter DATA_WIDTH = 8,
            parameter DATA_PERIOD = 1000
            //parameter ADDRESS = 7'h38
        )
        ( input wire clk_in,
          input wire rst_in,
          input wire [DATA_WIDTH-1:0] data_in,
          input wire trigger_in,
          
          input wire [6:0] ADDRESS,
          
          output logic [DATA_WIDTH-1:0] data_out,
          output logic valid_data,
          
          output logic i2c_clk, // clock
          inout wire i2c_sda // data
        );

  typedef enum { IDLE=0, START=1, SEND_ADDRESS=2, SET_DATA_ADDRESS=3, END=4,
                  START2=5, SEND_ADDRESS2=6, RECEIVE_DATA=7, END2=8, BUFFER=9} i2c_state;  
  i2c_state state;
  

  logic sda_val;
  assign i2c_sda = sda_val ? 1'bz : 1'b0;

  logic [$clog2(DATA_PERIOD)-1:0] HALF_PERIOD; // 50%
  assign HALF_PERIOD = DATA_PERIOD/2;
  
  logic [$clog2(DATA_PERIOD):0] FULL_PERIOD; // 100%
  assign FULL_PERIOD = HALF_PERIOD*2;
  
  logic [$clog2(DATA_PERIOD):0] WRITE_PERIOD; // 25%
  assign WRITE_PERIOD = FULL_PERIOD; // HALF_PERIOD/2;
  
  logic [$clog2(DATA_PERIOD):0] READ_PERIOD; // 75%
  assign READ_PERIOD = HALF_PERIOD/2 + HALF_PERIOD;
  
  
  logic [$clog2(DATA_PERIOD):0] period_counter;
  
  logic [DATA_WIDTH-1:0] address;
  logic [DATA_WIDTH-1:0] data;
  logic [31:0] sending_i;
  
  logic ack_p = 0; // ack primary flag (if 1, the fpga should send a 1)
  logic ack_s = 0; // ack secondary flag (if 1, the fpga should receive a 0)
  
  always_ff @(posedge clk_in) begin
  
    if (rst_in) begin
      // initialize vars
      state <= IDLE;
      period_counter <= 0;
      i2c_clk <= 1;
      sda_val <= 1;
      ack_s <= 0;
      ack_p <= 0;
      valid_data <= 0;
    end
    else if (ack_s) begin
      if (period_counter == READ_PERIOD-1) begin
        if (i2c_sda != 0) begin
          state <= IDLE; // if not ack, idle
          data_out <= 0;
          valid_data <= 1;
        end
        ack_s <= 0;
      end
    end
    else if (ack_p) begin
      if (period_counter == WRITE_PERIOD-1) begin
        sda_val <= 0;
        ack_p <= 0;
      end
    end
    else begin
    
      case (state)
        
        IDLE: begin
          // WAIT FOR A TOUCH, THEN LOAD IN THE ADDRESS (of device) AND DATA (aka register wanted: e.g., x_pos, y_pos)
        
          period_counter <= 0;
          i2c_clk <= 1;
          sda_val <= 1;
          ack_s <= 0;
          ack_p <= 0;
          valid_data <= 0;
        
          if (trigger_in) begin
            period_counter <= 0;
            address <= { ADDRESS, 1'b0 };
            data <= data_in;
            
            state <= START;
          end
        end
        
        START: begin
          // BRING SDA LOW BEFORE THE CLOCK STARTS (I2C)
          
          if (period_counter == WRITE_PERIOD/2-1) begin
            sda_val <= 0;
            state <= SEND_ADDRESS;
            sending_i <= DATA_WIDTH;
          end
          
        end
        
        SEND_ADDRESS: begin
          // PUMP IN THE DEVICE ADDRESS THEN W
          // wait for device to ACK after
          
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // address is fully transmitted
              ack_s <= 1;
              sda_val <= 1; // let go of line
              state <= SET_DATA_ADDRESS;
              sending_i <= DATA_WIDTH;
            end else begin
              // go to next index of address
              sda_val <= address[sending_i-1]; // transmit next piece of address
              sending_i <= sending_i - 1;
            end
          end
        end
        
        SET_DATA_ADDRESS: begin
          // PUMP IN THE REGISTER WANTED
          // wait for device to ACK after
        
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // data is fully transmitted
              ack_s <= 1;
              state <= END;
              sending_i <= 2;
            end else begin
              // go to next index of data
              sda_val <= data[sending_i-1]; // transmit next piece of data
              sending_i <= sending_i - 1;
            end
          end
        end
        
        END: begin
          // WAIT FOR CLOCK TO GO HIGH THEN SET DATA HIGH (I2C)
        
          if (sending_i == 2) begin
            if (period_counter == WRITE_PERIOD-1) begin
              sda_val <= 0;
              sending_i <= sending_i - 1;
            end
          end
          else if (sending_i == 1) begin
            if (period_counter == READ_PERIOD-1) begin
              sda_val <= 1;
              state <= BUFFER;
              sending_i <= DATA_PERIOD;
              //valid_data <= 1;
            end
          end
        end
        
        BUFFER: begin
          // WAIT A BIT (determined by previous state), THEN PROCEED WITH GRABBING DATA :)
          // update address so now we're reading
        
          if (sending_i == 0) begin
            period_counter <= 0;
            state <= START2;
            address <= { ADDRESS, 1'b1 };
          end
          else begin
            sending_i <= sending_i - 1;
          end
        end
        
        START2: begin
          // BRING SDA LOW BEFORE THE CLOCK STARTS (I2C)
          
          if (period_counter == WRITE_PERIOD/2-1) begin
            //sda_val <= ADDRESS[sending_i-1];
            sda_val <= 0;
            state <= SEND_ADDRESS2;
            sending_i <= DATA_WIDTH;
          end
          
        end
        
        SEND_ADDRESS2: begin
          // PUMP IN THE DEVICE ADDRESS THEN R
          // wait for device to ACK after
        
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // address is fully transmitted
              ack_s <= 1;
              sda_val <= 1; // let go of line
              state <= RECEIVE_DATA;
              sending_i <= DATA_WIDTH;
            end else begin
              // go to next index of address
              sda_val <= address[sending_i-1]; // transmit next piece of address
              sending_i <= sending_i - 1;
            end
          end
        end
        
        RECEIVE_DATA: begin
          // RECEIVE 8 BITS OF DATA FROM THE DEVICE
          // FPGA must ACK after
        
          if (period_counter == WRITE_PERIOD-1) begin
            if (sending_i == 0) begin
              // data is fully received
              ack_p <= 1;
              sending_i <= 1;
              state <= END2;
            end else begin
              // go to next index of data
              data_out[sending_i-1] <= i2c_sda; // transmit next piece of data
              sending_i <= sending_i - 1;
            end
          end
        end
        
        END2: begin
          // WAIT FOR CLOCK TO GO HIGH THEN SET DATA HIGH (I2C)
          
          if (sending_i == 2) begin
            if (period_counter == WRITE_PERIOD-1) begin
              sda_val <= 0;
              sending_i <= sending_i - 1;
            end
          end
          else if (sending_i == 1) begin
            if (period_counter == READ_PERIOD-1) begin
              sda_val <= 1;
              state <= IDLE;
              valid_data <= 1;
            end
          end
        end
      endcase
    end
    
    if (state != IDLE && state != BUFFER) begin
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

