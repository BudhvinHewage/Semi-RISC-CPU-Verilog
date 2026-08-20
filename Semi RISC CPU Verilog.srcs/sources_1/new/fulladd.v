`timescale 1ns / 1ps

module fulladd(
    input  Cin, x, y,
    output s, Cout
);
    assign s    = x ^ y ^ Cin;
    assign Cout = (x & y) | (Cin & x) | (Cin & y);
endmodule
