`timescale 1ns / 1ps

module data_path(
    input  clk, mclk,
    input  wen, en,
    input  clr_a, ld_a,
    input  clr_b, ld_b,
    input  clr_c, ld_c,
    input  clr_z, ld_z,
    input  clr_pc, ld_pc,
    input  clr_ir, ld_ir,
    output [31:0] out_a, out_b, out_c,
    output out_z,
    output [31:0] out_pc, out_ir,
    input  inc_pc,
    output [31:0] addr_out,
    input  [31:0] data_in,
    output [31:0] data_bus, mem_out, mem_in,
    output [7:0]  mem_addr,
    output [31:0] alu_out,
    input  [1:0]  data_mux_sel,
    input         reg_mux_sel,
    input         a_mux_sel, b_mux_sel,
    input         im_mux1_sel,
    input  [1:0]  im_mux2_sel,
    input  [2:0]  alu_op
);

    wire [31:0] ir_out;
    wire [31:0] data_bus_s;
    wire [31:0] lze_out_pc, lze_out_a_mux, lze_out_b_mux;
    wire [7:0]  red_out_data_mem;
    wire [31:0] a_mux_out, b_mux_out;
    wire [31:0] reg_a_out, reg_b_out;
    wire [31:0] reg_mux_out;
    wire [31:0] data_mem_out;
    wire [31:0] uze_im_mux1_out, im_mux1_out;
    wire [31:0] lze_im_mux2_out, im_mux2_out;
    wire [31:0] alu_out_s;
    wire        zero_flag, carry_flag;
    wire [31:0] out_pc_sig;

    // ---- IR / PC path ----
    register32 IR (
        .d(data_bus_s), .ld(ld_ir), .clr(clr_ir), .clk(clk), .Q(ir_out)
    );

    LZE LZE_PC ( .LZE_in(ir_out), .LZE_out(lze_out_pc) );

    pc PC0 (
        .clr(clr_pc), .clk(clk), .ld(ld_pc), .inc(inc_pc),
        .d(lze_out_pc), .q(out_pc_sig)
    );

    // ---- Register A path ----
    LZE LZE_A_Mux ( .LZE_in(ir_out), .LZE_out(lze_out_a_mux) );

    mux2to1 A_Mux0 (
        .s(a_mux_sel), .w0(data_bus_s), .w1(lze_out_a_mux), .f(a_mux_out)
    );

    register32 Reg_A (
        .d(a_mux_out), .ld(ld_a), .clr(clr_a), .clk(clk), .Q(reg_a_out)
    );

    // ---- Register B path ----
    LZE LZE_B_Mux ( .LZE_in(ir_out), .LZE_out(lze_out_b_mux) );

    mux2to1 B_Mux0 (
        .s(b_mux_sel), .w0(data_bus_s), .w1(lze_out_b_mux), .f(b_mux_out)
    );

    register32 Reg_B (
        .d(b_mux_out), .ld(ld_b), .clr(clr_b), .clk(clk), .Q(reg_b_out)
    );

    // ---- Memory path ----
    mux2to1 Reg_Mux0 (
        .s(reg_mux_sel), .w0(reg_a_out), .w1(reg_b_out), .f(reg_mux_out)
    );

    RED RED_Data_Mem ( .RED_in(ir_out), .RED_out(red_out_data_mem) );

    data_mem Data_Mem0 (
        .clk(mclk), .addr(red_out_data_mem), .data_in(reg_mux_out),
        .wen(wen), .en(en), .data_out(data_mem_out)
    );

    // ---- ALU operand muxes ----
    UZE UZE_IM_MUX1 ( .UZE_in(ir_out), .UZE_out(uze_im_mux1_out) );

    mux2to1 IM_MUX1a (
        .s(im_mux1_sel), .w0(reg_a_out), .w1(uze_im_mux1_out), .f(im_mux1_out)
    );

    LZE LZE_IM_MUX2 ( .LZE_in(ir_out), .LZE_out(lze_im_mux2_out) );

    mux4to1 IM_MUX2a (
        .s(im_mux2_sel),
        .X1(reg_b_out), .X2(lze_im_mux2_out), .X3(32'd1), .X4(32'd0),
        .f(im_mux2_out)
    );

    // ---- ALU + bus mux ----
    ALU ALU0 (
        .a(im_mux1_out), .b(im_mux2_out), .op(alu_op),
        .result(alu_out_s), .zero(zero_flag), .cout(carry_flag)
    );

    mux4to1 DATA_MUX0 (
        .s(data_mux_sel),
        .X1(data_in), .X2(data_mem_out), .X3(alu_out_s), .X4(32'd0),
        .f(data_bus_s)
    );

    // ---- Status flag registers ----
    register1 Reg_C (
        .d(carry_flag), .ld(ld_c), .clr(clr_c), .clk(clk), .Q(out_c)
    );

    register1 Reg_Z (
        .d(zero_flag), .ld(ld_z), .clr(clr_z), .clk(clk), .Q(out_z)
    );

    assign data_bus  = data_bus_s;
    assign out_a     = reg_a_out;
    assign out_b     = reg_b_out;
    assign out_ir    = ir_out;
    assign addr_out  = out_pc_sig;
    assign out_pc    = out_pc_sig;
    assign mem_addr  = red_out_data_mem;
    assign mem_in    = reg_mux_out;
    assign mem_out   = data_mem_out;
    assign alu_out   = alu_out_s;

endmodule