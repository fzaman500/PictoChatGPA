`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module baud_clk(
    input wire clk,
    input wire rst_in,
    input wire enable,
    output logic tick // generate a tick at the specified baud rate * oversampling
    );
    parameter ClkFrequency = 100000000; //100MHz
    parameter Baud = 115200;
    parameter Oversampling = 1;

    localparam AccWidth = $clog2(ClkFrequency/Baud)+8; // +/- 2% max timing error over a byte

    logic [AccWidth:0] Acc; //I NEED TO ACTUALLY SET THIS TO 0 IN RST RIGHT
    

    localparam ShiftLimiter = $clog2(Baud*Oversampling >> (31-AccWidth));

    // this makes sure Inc calculation doesn’t overflow

    localparam Inc = ((Baud*Oversampling << (AccWidth-ShiftLimiter))+(ClkFrequency>>(ShiftLimiter+1)))/(ClkFrequency>>ShiftLimiter);

    always @(posedge clk) begin
        if (rst_in) begin
            Acc <= 0;
        end
        else if(enable) begin 
            Acc <= Acc[AccWidth-1:0] + Inc[AccWidth:0];
        end else begin
            Acc <= Inc[AccWidth:0];
        end
    end

    assign tick = Acc[AccWidth];

endmodule
`default_nettype wire