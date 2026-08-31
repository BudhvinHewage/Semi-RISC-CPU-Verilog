`timescale 1ns / 1ps

module cpu_basys3_top(
    input  CLK100MHZ,
    input  BTNC,        // clock-step. Raw edge-detect only below -
                         // swap in your own debounced version here.
    input  BTNU,         // reset (level-sensitive, matches reset_circuit)
    input  [5:0] SW,     // SW0=A SW1=B SW2=PC SW3=IR SW4=status-C SW5=status-Z
    output [6:0] SEG,
    output [3:0] AN,
    output [15:0] LED
);

    // ---- Clock stepping ----
    // PLACEHOLDER: plain rising-edge detector, no debounce yet.
    // Replace clk_edge's source with your debounce module's output
    // once it's built - everything below stays the same.
    reg btn_prev;
    wire clk_edge;
    always @(posedge CLK100MHZ) btn_prev <= BTNC;
    assign clk_edge = BTNC & ~btn_prev;

    wire [31:0] cpu_to_mem, mem_to_cpu, addr_from_cpu;
    wire [31:0] out_a, out_b, out_ir, out_pc, out_alu;
    wire out_c, out_z;
    wire [2:0] t_info;

    instr_mem imem (
        .clock(CLK100MHZ),
        .address(addr_from_cpu[5:0]),
        .data(cpu_to_mem),
        .wren(1'b0),
        .q(mem_to_cpu)
    );

    cpu cpu (
        .clk(clk_edge), .mem_clk(CLK100MHZ), .rst(BTNU),
        .data_in(mem_to_cpu), .data_out(cpu_to_mem),
        .addr_out(addr_from_cpu),
        .dout_a(out_a), .dout_b(out_b),
        .dout_c(out_c), .dout_z(out_z),
        .dout_ir(out_ir), .dout_pc(out_pc),
        .out_t(t_info),
        .wen_mem(), .en_mem(),
        .dout_alu(out_alu)
    );

    // ---- Display selection ----
    // SW0=A  SW1=B  SW2=PC  SW3=IR  SW4=status C  SW5=status Z
    // Priority: SW0 highest, SW5 lowest; defaults to A if none are set.
    reg [31:0] display_value;
    reg [12:0] led_upper;

    always @(*) begin
        if (SW[0])      begin display_value = out_a;          led_upper = out_a[31:19];  end
        else if (SW[1]) begin display_value = out_b;          led_upper = out_b[31:19];  end
        else if (SW[2]) begin display_value = out_pc;         led_upper = out_pc[31:19]; end
        else if (SW[3]) begin display_value = out_ir;         led_upper = out_ir[31:19]; end
        else if (SW[4]) begin display_value = {31'b0, out_c}; led_upper = 13'b0;         end
        else if (SW[5]) begin display_value = {31'b0, out_z}; led_upper = 13'b0;         end
        else if (SW[6]) begin display_value = out_alu;        led_upper = out_alu[31:19];end
        else            begin display_value = out_a;          led_upper = out_a[31:19];  end
    end

    // LD0-2 always show the current T-state, regardless of SW selection.
    // t_info is already one-hot (001/010/100), so no decoding needed.
    assign LED[2:0]  = t_info;
    assign LED[15:3] = led_upper;

    sseg_display disp (
        .clk(CLK100MHZ),
        .value(display_value[15:0]),
        .seg(SEG),
        .an(AN)
    );

endmodule