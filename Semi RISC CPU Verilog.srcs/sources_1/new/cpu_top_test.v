`timescale 1ns / 1ps

module cpu_top_test(
    input  cpu_clk, mem_clk, rst,
    output [31:0] out_a, out_b,
    output out_c, out_z,
    output [31:0] out_ir, out_pc, out_bus,
    output [2:0]  t_info,
    output [31:0] out_alu,
    output test_signal
);
    wire [31:0] cpu_to_mem, mem_to_cpu, addr_from_cpu;
    wire wen_mem_dbg, en_mem_dbg;

    instr_mem imem (
        .clock(mem_clk),
        .address(addr_from_cpu[5:0]),
        .data(cpu_to_mem),
        .wren(1'b0),          
        .q(mem_to_cpu)
    );

    cpu cpu (
        .clk(cpu_clk), .mem_clk(mem_clk), .rst(rst),
        .data_in(mem_to_cpu), .data_out(cpu_to_mem),
        .addr_out(addr_from_cpu),
        .dout_a(out_a), .dout_b(out_b),
        .dout_c(out_c), .dout_z(out_z),
        .dout_ir(out_ir), .dout_pc(out_pc),
        .out_t(t_info),
        .wen_mem(wen_mem_dbg), .en_mem(en_mem_dbg),
        .dout_alu(out_alu), .test_signal(test_signal)
    );
    
    assign out_bus = mem_to_cpu;
endmodule