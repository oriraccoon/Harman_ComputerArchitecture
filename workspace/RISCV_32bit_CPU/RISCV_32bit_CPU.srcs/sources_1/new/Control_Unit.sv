`timescale 1ns / 1ps
`include "defined.sv"

module ControlUnit (
    input logic [31:0] instr_code,

    output logic       regFileWe,
    output logic [3:0] alucode,
    output logic [2:0] Lcode,
    output logic [2:0] wdSrcMuxSel,
    output logic       aluSrcMuxSel,
    output logic [1:0] pcSrcMuxSel,
    output logic       dataWe
);

    //-------------------------------------------------------------------------------
    //  variable declaration
    //-------------------------------------------------------------------------------

    wire [6:0] opcode = instr_code[6:0];
    wire [3:0] r_oper = {instr_code[30], instr_code[14:12]};
    wire [2:0] lisb_oper = instr_code[14:12];

    logic [14:0] out_signal;
    assign {dataWe, wdSrcMuxSel, aluSrcMuxSel, pcSrcMuxSel, regFileWe, alucode, Lcode} = out_signal;


    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

    //-------------------------------------------------------------------------------
    //  Opcode_Analysis
    //-------------------------------------------------------------------------------

    always_comb begin
        out_signal = 0;
        case (opcode)
            `R_TYPE: begin
                out_signal = {8'b0_000_0_00_1, r_oper, 3'bx};
            end
            `L_TYPE: begin
                out_signal = {8'b0_001_1_00_1, `ADD, lisb_oper};
            end
            `I_TYPE: begin
                case (lisb_oper)
                    `SLLI, `SRLI, `SRAI: out_signal = {8'b0_000_1_00_1, r_oper, 3'bx};
                    default: out_signal = {8'b0_000_1_00_1, {1'b0, lisb_oper}, 3'bx};
                endcase
                
            end
            `S_TYPE: begin
                out_signal = {8'b1_000_1_00_0, `ADD, lisb_oper};
            end
            `B_TYPE: begin
                out_signal = {8'b0_000_1_01_0, {1'b0, lisb_oper}, 3'bx};
            end
            `LU_TYPE: begin
                out_signal = {8'b0_010_1_00_1, `SLL, 3'bx};
            end
            `AU_TYPE: begin
                out_signal = {8'b0_011_1_01_1, `SLL, 3'bx};
            end
            `J_TYPE: begin
                out_signal = {8'b0_100_1_10_1, `SLL, 3'bx};
            end
            `JL_TYPE: begin
                out_signal = {8'b0_100_1_10_1, `SLL, 3'bx};
            end
        endcase
    end


    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

endmodule
