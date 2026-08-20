`timescale 1ns / 1ps

module UZE(
    input  [31:0] UZE_in,
    output [31:0] UZE_out
);
    assign UZE_out = {UZE_in[15:0], 16'b0};
endmodule
