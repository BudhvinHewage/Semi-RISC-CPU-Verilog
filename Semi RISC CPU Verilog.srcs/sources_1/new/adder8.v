`timescale 1ns / 1ps

module adder8(
    input        Cin,
    input  [7:0] X, Y,
    output [7:0] S,
    output       Cout
);
    wire C;

    adder4 stage0 (.Cin(Cin), .X(X[3:0]), .Y(Y[3:0]), .S(S[3:0]), .Cout(C));
    adder4 stage1 (.Cin(C),   .X(X[7:4]), .Y(Y[7:4]), .S(S[7:4]), .Cout(Cout));
endmodule
