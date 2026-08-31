`timescale 1ns / 1ps

module control(
    input  clk, mclk,
    input  enable,
    input  status_c, status_z,
    input  [31:0] inst,
    output reg a_mux, b_mux,
    output reg im_mux1, reg_mux,
    output reg [1:0] im_mux2, data_mux,
    output reg [2:0] alu_op,
    output reg inc_pc, ld_pc,
    output reg clr_ir, ld_ir,
    output reg clr_a, clr_b, clr_c, clr_z,
    output reg ld_a, ld_b, ld_c, ld_z,
    output reg [2:0] t,
    output reg wen, en
);

    localparam STATE_0 = 2'b00, STATE_1 = 2'b01, STATE_2 = 2'b10;
    reg [1:0] present_state;

    wire [3:0] instruction_sig  = inst[31:28];
    wire [7:0] instruction_sig2 = inst[31:24];

    localparam ALU_AND=3'b000, ALU_OR=3'b001, ALU_ADD=3'b010, ALU_PASSB=3'b011,
               ALU_SHL=3'b100,  ALU_SHR=3'b101, ALU_SUB=3'b110;

    always @(posedge clk or negedge enable) begin
        if (!enable)
            present_state <= STATE_0;
        else begin
            case (present_state)
                STATE_0: present_state <= STATE_1;
                STATE_1: present_state <= STATE_2;
                default: present_state <= STATE_0;
            endcase
        end
    end

    always @(*) begin
        case (present_state)
            STATE_0: t = 3'b001;
            STATE_1: t = 3'b010;
            STATE_2: t = 3'b100;
            default: t = 3'b001;
        endcase
    end

    always @(*) begin
        if (enable) begin
            case (present_state)

                // T0 
                STATE_0: begin
                    data_mux = 2'b00;
                    ld_ir = 1'b1; clr_ir = 1'b0;
                    ld_pc = 1'b0; inc_pc = 1'b0;
                    clr_a=1'b0; ld_a=1'b0; clr_b=1'b0; ld_b=1'b0;
                    clr_c=1'b0; ld_c=1'b0; clr_z=1'b0; ld_z=1'b0;
                    en=1'b0; wen=1'b0;
                    a_mux=1'b0; b_mux=1'b0; im_mux1=1'b0; im_mux2=2'b00;
                    reg_mux=1'b0; alu_op=ALU_ADD;
                end

                // T1 — default advances PC; a few instructions need
                // memory/flag signals asserted early (setup margin)
                STATE_1: begin
                    clr_ir=1'b0; ld_ir=1'b0;
                    ld_pc=1'b1; inc_pc=1'b1;
                    clr_a=1'b0; ld_a=1'b0; clr_b=1'b0; ld_b=1'b0;
                    clr_c=1'b0; ld_c=1'b0; clr_z=1'b0; ld_z=1'b0;
                    en=1'b0; wen=1'b0;
                    a_mux=1'b0; b_mux=1'b0; im_mux1=1'b0; im_mux2=2'b00;
                    reg_mux=1'b0; alu_op=ALU_ADD;

                    case (instruction_sig)
                        4'b0010: begin en=1'b1; wen=1'b1; reg_mux=1'b0; end // STA
                        4'b0011: begin en=1'b1; wen=1'b1; reg_mux=1'b1; end // STB
                        4'b1001: en=1'b1;                                   // LDA
                        4'b1010: en=1'b1;                                   // LDB
                        4'b0110, 4'b1000: begin // BEQ / BNE — compare early
                            im_mux1=1'b0; im_mux2=2'b00;
                            alu_op=ALU_SUB; ld_z=1'b1;
                        end
                        default: ; // everything else uses the T1 default above
                    endcase
                end

                // T2 
                STATE_2: begin
                    clr_ir=1'b0; ld_ir=1'b0;
                    ld_pc=1'b0; inc_pc=1'b0;   // T1 already advanced PC
                    clr_a=1'b0; ld_a=1'b0; clr_b=1'b0; ld_b=1'b0;
                    clr_c=1'b0; ld_c=1'b0; clr_z=1'b0; ld_z=1'b0;
                    en=1'b0; wen=1'b0;
                    a_mux=1'b0; b_mux=1'b0; im_mux1=1'b0; im_mux2=2'b00;
                    reg_mux=1'b0; data_mux=2'b00; alu_op=ALU_ADD;

                    case (instruction_sig)

                        4'b0000: begin // LDAI: A <= IR[15:0]
                            a_mux=1'b1; ld_a=1'b1;
                        end
                        4'b0001: begin // LDBI: B <= IR[15:0]
                            b_mux=1'b1; ld_b=1'b1;
                        end
                        4'b0010: begin // STA — write already committed in T1
                            en=1'b1; wen=1'b1; reg_mux=1'b0;
                        end
                        4'b0011: begin // STB
                            en=1'b1; wen=1'b1; reg_mux=1'b1;
                        end
                        4'b0100: begin // LUI: A[31:16]<=IR[15:0], A[15:0]<=0
                            im_mux1=1'b1; im_mux2=2'b11; alu_op=ALU_ADD;
                            data_mux=2'b10; a_mux=1'b0; ld_a=1'b1;
                        end
                        4'b0101: begin // JMP: unconditional
                            ld_pc=1'b1; inc_pc=1'b0;
                        end
                        4'b0110: begin // BEQ: taken when status_z==1
                            if (status_z) begin ld_pc=1'b1; inc_pc=1'b0; end
                        end
                        4'b1000: begin // BNE: taken when status_z==0
                            if (!status_z) begin ld_pc=1'b1; inc_pc=1'b0; end
                        end
                        4'b1001: begin // LDA: A <= M[ADDRS]
                            en=1'b1; data_mux=2'b01; a_mux=1'b0; ld_a=1'b1;
                        end
                        4'b1010: begin // LDB
                            en=1'b1; data_mux=2'b01; b_mux=1'b0; ld_b=1'b1;
                        end

                        4'b0111: begin // Data-processing instructions
                            case (instruction_sig2)
                                8'h70: begin // ADD: A <= A+B
                                    im_mux2=2'b00; alu_op=ALU_ADD;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h71: begin // ADDI: A <= A+IR[15:0]
                                    im_mux2=2'b01; alu_op=ALU_ADD;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h72: begin // SUB: A <= A-B
                                    im_mux2=2'b00; alu_op=ALU_SUB;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h73: begin // INCA: A <= A+1
                                    im_mux2=2'b10; alu_op=ALU_ADD;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h74: begin // ROL: A <= A<<1
                                    alu_op=ALU_SHL; data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h75: clr_a=1'b1;                     // CLRA
                                8'h76: clr_b=1'b1;                     // CLRB
                                8'h77: clr_c=1'b1;                     // CLRC
                                8'h78: clr_z=1'b1;                     // CLRZ
                                8'h79: begin // ANDI: A <= A AND IR[15:0]
                                    im_mux2=2'b01; alu_op=ALU_AND;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h7A: begin // TSTZ: if Z, skip next instr
                                    if (status_z) begin ld_pc=1'b1; inc_pc=1'b1; end
                                end
                                8'h7B: begin // AND: A <= A AND B
                                    im_mux2=2'b00; alu_op=ALU_AND;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h7C: begin // TSTC: if C, skip next instr
                                    if (status_c) begin ld_pc=1'b1; inc_pc=1'b1; end
                                end
                                8'h7D: begin // ORI: A <= A OR IR[15:0]
                                    im_mux2=2'b01; alu_op=ALU_OR;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h7E: begin // DECA: A <= A-1
                                    im_mux2=2'b10; alu_op=ALU_SUB;
                                    data_mux=2'b10; ld_a=1'b1;
                                end
                                8'h7F: begin // ROR: A <= A>>1
                                    alu_op=ALU_SHR; data_mux=2'b10; ld_a=1'b1;
                                end
                                default: ;
                            endcase
                        end

                        default: ; // undefined opcode — idle
                    endcase
                end

                default: ;
            endcase
        end
    end

endmodule