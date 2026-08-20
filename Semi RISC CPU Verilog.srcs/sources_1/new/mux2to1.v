`timescale 1ns / 1ps

module mux2to1(
    input         s,
    input  [31:0] w0, w1,
    output [31:0] f
);
    assign f = s ? w1 : w0;
endmodule
