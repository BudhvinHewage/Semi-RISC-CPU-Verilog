`timescale 1ns / 1ps

module cpu(
    input  clk,
    input  mem_clk,
    input  rst,
    input  [31:0] data_in,
    output [31:0] data_out,
    output [31:0] addr_out,
    output [31:0] dout_a,
    output [31:0] dout_b,
    output        dout_c,
    output        dout_z,
    output [31:0] dout_ir,
    output [31:0] dout_pc,
    output [2:0]  out_t,
    output        wen_mem,
    output        en_mem
);

    wire dp_mux1, dp_clr_a, dp_ld_a, dp_clr_b, dp_ld_b, dp_clr_c, dp_ld_c;
    wire dp_clr_z, dp_ld_z, mem_wen, mem_en, dp_mux_a, dp_mux_b;
    wire reg_sel, enpd, ir_clr, ir_ld, pc_inc, pc_clr, pc_ld;
    wire out_c, out_z;
    wire [31:0] out_ir_sig;
    wire [2:0]  alu_op_sig;
    wire [1:0]  im_mux2_sig, data_mux_sig;

    data_path dat (
        .clk(clk), .mclk(mem_clk),
        .wen(mem_wen), .en(mem_en),
        .clr_a(dp_clr_a), .ld_a(dp_ld_a),
        .clr_b(dp_clr_b), .ld_b(dp_ld_b),
        .clr_c(dp_clr_c), .ld_c(dp_ld_c),
        .clr_z(dp_clr_z), .ld_z(dp_ld_z),
        .clr_pc(pc_clr), .ld_pc(pc_ld),
        .clr_ir(ir_clr), .ld_ir(ir_ld),
        .out_a(dout_a), .out_b(dout_b), .out_c(out_c), .out_z(out_z),
        .out_pc(dout_pc), .out_ir(out_ir_sig),
        .inc_pc(pc_inc),
        .addr_out(addr_out), .data_in(data_in), .data_bus(data_out),
        .data_mux_sel(data_mux_sig), .reg_mux_sel(reg_sel),
        .a_mux_sel(dp_mux_a), .b_mux_sel(dp_mux_b),
        .im_mux1_sel(dp_mux1), .im_mux2_sel(im_mux2_sig),
        .alu_op(alu_op_sig)
    );

    // ---- Placeholder — swap in once Control_New.v exists ----
    // Expected interface, taken directly from the VHDL component decl:
    // control_new control_unit (
    //     .clk(clk), .mclk(mem_clk), .enable(enpd),
    //     .status_c(out_c), .status_z(out_z), .inst(out_ir_sig),
    //     .a_mux(dp_mux_a), .b_mux(dp_mux_b),
    //     .im_mux1(dp_mux1), .reg_mux(reg_sel),
    //     .im_mux2(im_mux2_sig), .data_mux(data_mux_sig),
    //     .alu_op(alu_op_sig),
    //     .inc_pc(pc_inc), .ld_pc(pc_ld),
    //     .clr_ir(ir_clr), .ld_ir(ir_ld),
    //     .clr_a(dp_clr_a), .clr_b(dp_clr_b), .clr_c(dp_clr_c), .clr_z(dp_clr_z),
    //     .ld_a(dp_ld_a), .ld_b(dp_ld_b), .ld_c(dp_ld_c), .ld_z(dp_ld_z),
    //     .t(out_t), .wen(mem_wen), .en(mem_en)
    // );

    reset_circuit reset (
        .Reset(rst), .Clk(clk),
        .Enable_PD(enpd), .Clr_PC(pc_clr)
    );

    assign dout_c  = out_c;
    assign dout_z  = out_z;
    assign dout_ir = out_ir_sig;
    assign wen_mem = mem_wen;   // fixed — see note above
    assign en_mem  = mem_en;    // fixed — see note above

endmodule