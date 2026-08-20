`timescale 1ns / 1ps

module mux4to1(
    input  [1:0]  s,
    input  [31:0] X1, X2, X3, X4,
    output reg [31:0] f
);
    always @(*) begin
        case (s)
            2'b00: f = X1;
            2'b01: f = X2;
            2'b10: f = X3;
            2'b11: f = X4;
        endcase
    end
endmodule
