`timescale 1ns / 1ps

// Holds Clr_PC high / Enable_PD low for 4 clock cycles after Reset
// deasserts, giving the surrounding datapath time to stabilize before
// the control unit starts running (see CPU spec, Lab 6 Part I).
module reset_circuit(
    input      Reset, Clk,
    output reg Enable_PD,
    output reg Clr_PC
);
    reg [1:0] settle_count;

    always @(posedge Clk) begin
        if (Reset) begin
            Clr_PC       <= 1'b1;
            Enable_PD    <= 1'b0;
            settle_count <= 2'd0;
        end else if (settle_count == 2'd3) begin
            Clr_PC    <= 1'b0;
            Enable_PD <= 1'b1;
        end else begin
            settle_count <= settle_count + 1'b1;
        end
    end
endmodule
