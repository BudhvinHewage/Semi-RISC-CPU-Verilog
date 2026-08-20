`timescale 1ns / 1ps

module register1(
    input  d, ld, clr, clk,
    output reg Q
);
    always @(posedge clk or posedge clr) begin
        if (clr)
            Q <= 1'b0;
        else if (ld)
            Q <= d;
    end
endmodule
