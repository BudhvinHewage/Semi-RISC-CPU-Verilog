`timescale 1ns / 1ps

module pc(
    input         clr, clk, ld, inc,
    input  [31:0] d,
    output [31:0] q
);
    wire [31:0] add_out, mux_out, q_out;

    add        add0 (.A(q_out), .B(add_out));
    mux2to1    mux0 (.s(inc), .w0(d), .w1(add_out), .f(mux_out));
    register32 reg0 (.d(mux_out), .ld(ld), .clr(clr), .clk(clk), .Q(q_out));

    assign q = q_out;
endmodule
