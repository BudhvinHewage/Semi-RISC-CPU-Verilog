`timescale 1ns / 1ps
module tb_cpu_top;
    reg clk, mclk, rst;
    wire [31:0] out_a, out_b, out_ir, out_pc;
    wire out_c, out_z;
    wire [2:0] t_info;

    cpu_top_test DUT (
        .cpu_clk(clk), .mem_clk(mclk), .rst(rst),
        .out_a(out_a), .out_b(out_b),
        .out_c(out_c), .out_z(out_z),
        .out_ir(out_ir), .out_pc(out_pc),
        .t_info(t_info)
    );

    always #5 clk  = ~clk;
    always #5 mclk = ~mclk;   

    initial begin
        clk = 0; mclk = 0; rst = 1;
        #40  rst = 0;
        #200 $finish;
    end
endmodule