`timescale 1ns / 1ps

module adder32(
    input         Cin,
    input  [31:0] X, Y,
    output [31:0] S,
    output        Cout
);
    wire C;

    adder16 stage0 (.Cin(Cin), .X(X[15:0]),  .Y(Y[15:0]),  .S(S[15:0]),  .Cout(C));
    adder16 stage1 (.Cin(C),   .X(X[31:16]), .Y(Y[31:16]), .S(S[31:16]), .Cout(Cout));
endmodule
