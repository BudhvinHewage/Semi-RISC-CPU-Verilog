`timescale 1ns / 1ps

module adder16(
    input         Cin,
    input  [15:0] X, Y,
    output [15:0] S,
    output        Cout
);
    wire [3:1] C;

    adder4 stage0 (.Cin(Cin),  .X(X[3:0]),   .Y(Y[3:0]),   .S(S[3:0]),   .Cout(C[1]));
    adder4 stage1 (.Cin(C[1]), .X(X[7:4]),   .Y(Y[7:4]),   .S(S[7:4]),   .Cout(C[2]));
    adder4 stage2 (.Cin(C[2]), .X(X[11:8]),  .Y(Y[11:8]),  .S(S[11:8]),  .Cout(C[3]));
    adder4 stage3 (.Cin(C[3]), .X(X[15:12]), .Y(Y[15:12]), .S(S[15:12]), .Cout(Cout));
endmodule
