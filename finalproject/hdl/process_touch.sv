`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
module process_touch(
    input wire [8:0] x,
    input wire [7:0] y,
    output [8:0] x_out,
    output [7:0] y_out,
    output [2:0] color,
    output active_draw
);

//colors 0=black, 1=blue, 2=red, 3=green, 4=white
//check drawing region
always_comb begin
    if (x < 60 && x > 20 && y < 220 && y > 20) begin
        active_draw = 0;
        if (y < 60) begin //black
            color = 0;
        end else if (y < 100) begin //blue
            color = 1;
        end else if (y < 140) begin // red
            color = 2;
        end else if (y < 180) begin //green
            color = 3;
        end else begin //white
            color = 4;
        end
    end else begin
        active_draw = 1;
    end
    x_out = x;
    y_out = y;
end

endmodule
`default_nettype wire