`timescale 1ns / 1ps

module RED(
    input  [31:0] RED_in,
    output [7:0]  RED_out
);
    assign RED_out = RED_in[7:0];
endmodule
