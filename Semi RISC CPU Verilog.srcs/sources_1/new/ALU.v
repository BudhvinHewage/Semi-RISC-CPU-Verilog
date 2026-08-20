`timescale 1ns / 1ps
module ALU(
    input  [31:0] a, b,
    input  [2:0]  op,
    output reg [31:0] result,
    output reg        zero,
    output reg        cout
);

    wire [31:0] result_add, result_sub;
    wire        cout_add,   cout_sub;

    adder32 add0 (.Cin(1'b0), .X(a), .Y(b),  .S(result_add), .Cout(cout_add));
    adder32 sub0 (.Cin(1'b1), .X(a), .Y(~b), .S(result_sub), .Cout(cout_sub));

    always @(*) begin
        case (op)
            3'b010: begin                 // ADD: a + b
                result = result_add;
                cout   = cout_add;
            end

            3'b110: begin                 // SUB: a - b
                result = result_sub;
                cout   = cout_sub;
            end

            3'b000: begin                 // AND
                result = a & b;
                cout   = 1'b0;
            end

            3'b001: begin                 // OR
                result = a | b;
                cout   = 1'b0;
            end

            3'b011: begin                 // pass B through
                result = b;
                cout   = 1'b0;
            end

            3'b100: begin                 // logical left shift
                result = a << 1;
                cout   = a[31];   
            end

            3'b101: begin                 // logical right shift
                result = a >> 1;
                cout   = 1'b0;
            end

            default: begin                // pass A through
                result = a;
                cout   = 1'b0;
            end
        endcase

        zero = (result == 32'b0);
    end
endmodule