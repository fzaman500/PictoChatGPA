`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
//don't worry about weird edge cases
//we want a clean 50% duty cycle clock signal
module display
       #(   
            parameter COLOR_WIDTH = 3,
            parameter NUM_COLS = 240,
            parameter NUM_ROWS = 320
        )
        ( input wire clk_in,
          input wire rst_in,
          input wire custom_in,
          input wire [$clog2(NUM_COLS)-1:0] col1_in,
          input wire [$clog2(NUM_COLS)-1:0] col2_in,
          input wire [$clog2(NUM_ROWS)-1:0] row1_in,
          input wire [$clog2(NUM_ROWS)-1:0] row2_in,
          input wire [COLOR_WIDTH-1:0] color_in,
          input wire valid_in,

          input wire [7:0] curr_color,
          
          input wire tft_sdo,
          output logic tft_sck,
          output logic tft_sdi, 
          output logic tft_dc,
          output logic tft_reset,
          output logic tft_cs,

          output logic drawn_finished,
          
          input wire [15:0] sw,
          output logic [4:0] state_out
        );

  
  
  localparam CUSTOM_DATA_SIZE = 2; // 52 instructions to send
  logic [5:0] custom_data_index;
  logic [0:CUSTOM_DATA_SIZE-1][8:0] CUSTOM_DATA;
  assign CUSTOM_DATA = {
    {1'b0, sw[15:8]},
    {1'b1, sw[7:0]}
  };

  localparam INIT_DATA_SIZE = 88; // instructions to send
  logic [10:0] init_data_index;
  logic [0:INIT_DATA_SIZE-1][8:0] INIT_DATA = {
    {1'b0, 8'hEF}, {1'b1, 8'h03}, {1'b1, 8'h80}, {1'b1, 8'h02},
    {1'b0, 8'hCF}, {1'b1, 8'h00}, {1'b1, 8'hC1}, {1'b1, 8'h30},
    {1'b0, 8'hED}, {1'b1, 8'h64}, {1'b1, 8'h03}, {1'b1, 8'h12}, {1'b1, 8'h81},
    {1'b0, 8'hE8}, {1'b1, 8'h85}, {1'b1, 8'h00}, {1'b1, 8'h78},
    {1'b0, 8'hCB}, {1'b1, 8'h39}, {1'b1, 8'h2C}, {1'b1, 8'h00}, {1'b1, 8'h34}, {1'b1, 8'h02},
    {1'b0, 8'hF7}, {1'b1, 8'h20},
    {1'b0, 8'hEA}, {1'b1, 8'h00}, {1'b1, 8'h00},
    {1'b0, 8'hC0}, {1'b1, 8'h23},             // Power control VRH[5:0]
    {1'b0, 8'hC1}, {1'b1, 8'h10},             // Power control SAP[2:0];BT[3:0]
    {1'b0, 8'hC5}, {1'b1, 8'h3e}, {1'b1, 8'h28},       // VCM control
    {1'b0, 8'hC7}, {1'b1, 8'h86},             // VCM control2
    {1'b0, 8'h36}, {1'b1, 8'h48},             // Memory Access Control
    {1'b0, 8'h37}, {1'b1, 8'h00},             // Vertical scroll zero
    {1'b0, 8'h3A}, {1'b1, 8'h55},
    {1'b0, 8'hB1}, {1'b1, 8'h00}, {1'b1, 8'h18},
    {1'b0, 8'hB6}, {1'b1, 8'h08}, {1'b1, 8'h82}, {1'b1, 8'h27}, // Display Function Control
    {1'b0, 8'hF2}, {1'b1, 8'h00},                         // 3Gamma Function Disable
    {1'b0, 8'h26}, {1'b1, 8'h01},             // Gamma curve selected
    {1'b0, 8'hE0}, {1'b1, 8'h0F}, {1'b1, 8'h31}, {1'b1, 8'h2B}, {1'b1, 8'h0C}, {1'b1, 8'h0E}, {1'b1, 8'h08}, // Set Gamma
      {1'b1, 8'h4E}, {1'b1, 8'hF1}, {1'b1, 8'h37}, {1'b1, 8'h07}, {1'b1, 8'h10}, {1'b1, 8'h03}, {1'b1, 8'h0E}, {1'b1, 8'h09}, {1'b1, 8'h00},
    {1'b0, 8'hE1}, {1'b1, 8'h00}, {1'b1, 8'h0E}, {1'b1, 8'h14}, {1'b1, 8'h03}, {1'b1, 8'h11}, {1'b1, 8'h07}, // Set Gamma
      {1'b1, 8'h31}, {1'b1, 8'hC1}, {1'b1, 8'h48}, {1'b1, 8'h08}, {1'b1, 8'h0F}, {1'b1, 8'h0C}, {1'b1, 8'h31}, {1'b1, 8'h36}, {1'b1, 8'h0F},
    {1'b0, 8'h11},                // Exit Sleep
    {1'b0, 8'h29}                // Display on
  };
  
  /*localparam DRAW_SEQ_SIZE = 29;
  logic [5:0] draw_seq_index;
  logic [0:DRAW_SEQ_SIZE-1][8:0] DRAW_SEQ;
  assign DRAW_SEQ = {
    // Set Column Address
    {1'b0, 8'h2A}, {1'b1, col1[15:8]}, {1'b1, col1[7:0]}, {1'b1, col2[15:8]}, {1'b1, col2[7:0]},
    // Set Page (Row) Address
    {1'b0, 8'h2B}, {1'b1, row1[15:8]}, {1'b1, row1[7:0]}, {1'b1, row2[15:8]}, {1'b1, row2[7:0]},
    // Memory Write
    {1'b0, 8'h2C}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}
    // COLORS
    
  };

  //BIGGER
  localparam DRAW_SEQ_SIZE_BIGGER = 43;
  logic [6:0] draw_seq_index_bigger;
  logic [0:DRAW_SEQ_SIZE-1][8:0] DRAW_SEQ_BIGGER;
  assign DRAW_SEQ_BIGGER = {
    // Set Column Address
    {1'b0, 8'h2A}, {1'b1, col1[15:8]}, {1'b1, col1[7:0]}, {1'b1, col2[15:8]}, {1'b1, col2[7:0]},
    // Set Page (Row) Address
    {1'b0, 8'h2B}, {1'b1, row1[15:8]}, {1'b1, row1[7:0]}, {1'b1, row2[15:8]}, {1'b1, row2[7:0]},
    // Memory Write
    {1'b0, 8'h2C}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}
    // COLORS
    
  };
*/

  localparam DRAW_SEQ_SIZE = 43;
  logic [6:0] draw_seq_index;
  logic [0:DRAW_SEQ_SIZE-1][8:0] DRAW_SEQ;
  assign DRAW_SEQ = {
    // Set Column Address
    {1'b0, 8'h2A}, {1'b1, col1[15:8]}, {1'b1, col1[7:0]}, {1'b1, col2[15:8]}, {1'b1, col2[7:0]},
    // Set Page (Row) Address
    {1'b0, 8'h2B}, {1'b1, row1[15:8]}, {1'b1, row1[7:0]}, {1'b1, row2[15:8]}, {1'b1, row2[7:0]},
    // Memory Write
    {1'b0, 8'h2C}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}, {1'b1, curr_color}
    // COLORS
    
  };

  // col and row are 16 bits since the display accepts 8 bits at a time for setting row/col. (For col, top 8 bits will always be 0)
  logic [15:0] col1;
  logic [15:0] col2;
  logic [15:0] row1;
  logic [15:0] row2;
  logic [COLOR_WIDTH-1:0] color;

  logic [31:0] STANDARD_DELAY; //clk_in * 5000;
  assign STANDARD_DELAY = 100;
  logic [31:0] delay;

  logic [8:0] data_in;
  logic trigger_in;
  
  logic sel_out;
  
  
  spi_tx spi
        ( .clk_in(clk_in),
          .rst_in(rst_in),
          .data_in(data_in),
          .trigger_in(trigger_in),
          .data_out(tft_sdi),
          .data_clk_out(tft_sck),
          .sel_out(sel_out),
          .dc_out(tft_dc)
        ); // to use: change data_in, trigger_in
  
  typedef enum { RESET=0, INIT=1, IDLE=2, DRAW=3, CUSTOM=4} touch_state;
  
  touch_state state;
  assign state_out = state;
  
    always_ff @(posedge clk_in) begin
  
    if (rst_in) begin
      tft_reset <= 0; // active low
    
      delay <= STANDARD_DELAY;
      init_data_index <= 0;
      custom_data_index <= 0;
      state <= RESET;
      drawn_finished <= 0;
    end
    else begin
      if (trigger_in) begin
        trigger_in <= 0; // reset trigger for SPI valid data
        
        if (state == INIT) data_in <= INIT_DATA[init_data_index];
        else if (state == DRAW) data_in <= DRAW_SEQ[draw_seq_index];
        else if (state == CUSTOM) data_in <= CUSTOM_DATA[custom_data_index];
        
      end
      else if (sel_out == 1 && delay > 0) begin // delay the program (wait for SPI commands to propogate)
        delay <= delay - 1;
        
        if (data_in[8] == 0) begin
          tft_cs <= 1;
        end
      end
      else if (sel_out == 1) begin
      
        // BEGIN STATE MACHINE //
      
        case (state)
        
          // reset via pin //
          RESET: begin
            tft_reset <= 1;
            delay <= 5*STANDARD_DELAY;
            state <= INIT;
          end
          
          INIT: begin
            // loop through init instructions
            
            if (init_data_index != INIT_DATA_SIZE) begin // still have data to send
              tft_cs <= 0;
              data_in <= INIT_DATA[init_data_index];
              trigger_in <= 1;
              
              init_data_index <= init_data_index + 1;
              delay <= STANDARD_DELAY;
            end else begin
              tft_cs <= 1;
              state <= IDLE;
            end
          end
          
          IDLE: begin
            drawn_finished <= 0;

            if (valid_in) begin
              col1 <= col1_in;
              col2 <= col2_in;
              row1 <= row1_in;
              row2 <= row2_in;
              color <= color_in;
              
              draw_seq_index <= 0;
              state <= DRAW;
            end
            else if (custom_in) begin
              delay <= STANDARD_DELAY;
              custom_data_index <= 0;
              state <= CUSTOM;
            end
          end
          
          CUSTOM: begin
            if (custom_data_index != CUSTOM_DATA_SIZE) begin // still have data to send
              tft_cs <= 0;
              data_in <= CUSTOM_DATA[custom_data_index];
              trigger_in <= 1;
              
              custom_data_index <= custom_data_index + 1;
              delay <= STANDARD_DELAY;
            end else begin
              tft_cs <= 1;
              state <= IDLE;
            end
          end
          DRAW: begin
            // loop through draw instructions
            if (draw_seq_index != DRAW_SEQ_SIZE) begin // still have data to send
              tft_cs <= 0;
              data_in <= DRAW_SEQ[draw_seq_index];
              trigger_in <= 1;
              
              draw_seq_index <= draw_seq_index + 1;
              delay <= STANDARD_DELAY;
            end else begin
              drawn_finished <= 1;
              tft_cs <= 1;
              state <= IDLE;
            end
          end
        endcase
      end
    end
    
  end

endmodule
`default_nettype wire // prevents system from inferring an undeclared logic (good practice)