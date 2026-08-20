`timescale 1ns / 1ps

module register32(
    input  [31:0] d,
    input         ld, clr, clk,
    output reg [31:0] Q
);
    always @(posedge clk or posedge clr) begin
        if (clr)
            Q <= 32'b0;
        else if (ld)
            Q <= d;
    end
endmodule
