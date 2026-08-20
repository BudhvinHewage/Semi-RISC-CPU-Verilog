`timescale 1ns / 1ps

module adder4(
    input        Cin,
    input  [3:0] X, Y,
    output [3:0] S,
    output       Cout
);
    wire [3:1] C;

    fulladd stage0 (.Cin(Cin),  .x(X[0]), .y(Y[0]), .s(S[0]), .Cout(C[1]));
    fulladd stage1 (.Cin(C[1]), .x(X[1]), .y(Y[1]), .s(S[1]), .Cout(C[2]));
    fulladd stage2 (.Cin(C[2]), .x(X[2]), .y(Y[2]), .s(S[2]), .Cout(C[3]));
    fulladd stage3 (.Cin(C[3]), .x(X[3]), .y(Y[3]), .s(S[3]), .Cout(Cout));
endmodule
