`timescale 1ns / 1ps

module LZE(
    input  [31:0] LZE_in,
    output [31:0] LZE_out
);
    assign LZE_out = {16'b0, LZE_in[15:0]};
endmodule
