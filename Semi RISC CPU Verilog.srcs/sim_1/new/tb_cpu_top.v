`timescale 1ns / 1ps

module tb_cpu_top;
    reg clk, mclk, rst;
    wire [31:0] out_a, out_b, out_ir, out_pc, out_alu, out_bus;
    wire out_c, out_z, test_signal;
    wire [2:0] t_info;
    

    cpu_top_test DUT (
        .cpu_clk(clk), .mem_clk(mclk), .rst(rst),
        .out_a(out_a), .out_b(out_b),
        .out_c(out_c), .out_z(out_z),
        .out_ir(out_ir), .out_pc(out_pc),
        .t_info(t_info), .out_alu(out_alu), .out_bus(out_bus), 
        .test_signal(test_signal)
    );

    always #10 clk  = ~clk;
    always #5 mclk = ~mclk;   

    initial begin
        clk = 0; mclk = 0; rst = 1;
        #40  rst = 0;
        #800 $finish;
    end
endmodule