`timescale 1ns / 1ps
`include "defined.sv"

module ControlUnit (
    input logic [31:0] instr_code,

    output logic       regFileWe,
    output logic [3:0] alucode,
    output logic       aluSrcMuxSel_rs1,
    output logic       aluSrcMuxSel_rs2,
    output logic       dataWe
);

    //-------------------------------------------------------------------------------
    //  variable declaration
    //-------------------------------------------------------------------------------

    wire [6:0] opcode = instr_code[6:0];
    wire [3:0] ri_oper = {instr_code[30], instr_code[14:12]};
    wire [2:0] lsb_oper = instr_code[14:12];

    logic [7:0] out_signal;
    assign {dataWe, aluSrcMuxSel_rs1, aluSrcMuxSel_rs2, regFileWe, alucode} = out_signal;


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
                out_signal = {4'b0_0_0_1, ri_oper};
            end
            `L_TYPE: begin
                out_signal = {4'b0_1_1_1, `ADD};
            end
            `I_TYPE: begin

            end
            `S_TYPE: begin
                out_signal = {4'b1_0_1_0, `ADD};
            end
            `B_TYPE: begin

            end
            `LU_TYPE: begin

            end
            `AU_TYPE: begin

            end
            `J_TYPE: begin

            end
            `JL_TYPE: begin

            end
        endcase
    end


    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

endmodule
