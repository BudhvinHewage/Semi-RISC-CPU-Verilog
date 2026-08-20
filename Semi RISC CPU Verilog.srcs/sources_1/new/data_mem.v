`timescale 1ns / 1ps

module data_mem(
    input         clk,
    input  [7:0]  addr,
    input  [31:0] data_in,
    input         wen, en,
    output reg [31:0] data_out
);
    reg [31:0] DATAMEM [0:255];

    always @(negedge clk) begin
        if (!en) begin
            data_out <= 32'b0;
        end else begin
            if (!wen)
                data_out <= DATAMEM[addr];
            if (wen) begin
                DATAMEM[addr] <= data_in;
                data_out      <= 32'b0;
            end
        end
    end
endmodule
