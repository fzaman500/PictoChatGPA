`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module spi_tx
       #(   parameter DATA_WIDTH = 8,
            parameter DATA_PERIOD = 100
        )
        ( input wire clk_in,
          input wire rst_in,
          input wire [DATA_WIDTH:0] data_in, // 9 bits, where the MSB is the dc_out
          input wire trigger_in,
          output logic data_out,
          output logic data_clk_out,
          output logic sel_out,
          output logic dc_out
        );

  logic [$clog2(DATA_PERIOD)-1:0] HALF_PERIOD;
  assign HALF_PERIOD = DATA_PERIOD/2;
  
  logic [$clog2(DATA_PERIOD):0] FULL_PERIOD;
  assign FULL_PERIOD = HALF_PERIOD*2;
  
  logic [$clog2(DATA_PERIOD):0] period_counter;
  
  logic [DATA_WIDTH:0] data;
  logic [DATA_WIDTH:0] data_i;
  
  
  always_ff @(posedge clk_in) begin
  
    if (rst_in) begin
      // grab data and initialize vars
      
      sel_out <= 1;
      data <= data_in; // grab and store clean data
      data_i <= DATA_WIDTH-1;
      period_counter <= 0;
      data_clk_out <= 0;
      data_out <= 1;
    end
    
    else if (sel_out & trigger_in) begin
      // begin transmission
      data_clk_out <= 0;
      sel_out <= 0;
      dc_out <= data_in[DATA_WIDTH];
      data_out <= data_in[data_i];
      data <= data_in; // grab and store clean data
    end
    else if (!sel_out) begin
      // transmitting data
      
      // update data_clk_out
      case (period_counter)
        FULL_PERIOD-1: begin
          data_clk_out <= 0;
          
          if (data_i == 0) begin
            // data is fully transmitted
            sel_out <= 1;
            data <= data_in; // grab and store clean data
            data_i <= DATA_WIDTH-1;

            data_out <= 1;
          end else begin
            // go to next index of data
            data_out <= data[data_i-1]; // transmit next piece of data
            data_i <= data_i - 1;
          end
        end
        HALF_PERIOD-1: data_clk_out <= 1;
      endcase
      
      // update period_counter
      if (period_counter == FULL_PERIOD-1) begin
        period_counter <= 0;
      end else begin
        period_counter <= period_counter + 1;
      end
      
    end
  end

endmodule
`default_nettype wire // prevents system from inferring an undeclared logic (good practice)

