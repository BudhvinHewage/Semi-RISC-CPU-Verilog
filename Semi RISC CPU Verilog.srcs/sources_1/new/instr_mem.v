`timescale 1ns / 1ps

module instr_mem(
    input         clock,
    input  [5:0]  address,
    input  [31:0] data,
    input         wren,
    output reg [31:0] q
);
    reg [31:0] mem [0:63];

    initial begin
        $readmemh("program.hex", mem);
    end

    always @(posedge clock) begin
        if (wren)
            mem[address] <= data;   // kept for interface parity — see note above
        q <= mem[address];          // registered read, matches outdata_reg_a
    end
endmodule