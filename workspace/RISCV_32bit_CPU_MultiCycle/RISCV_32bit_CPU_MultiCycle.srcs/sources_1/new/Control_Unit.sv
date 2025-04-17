`timescale 1ns / 1ps
`include "defined.sv"

module ControlUnit (
    input logic        clk,
    input logic        rst,

    input logic [31:0] instr_code,

    output logic       regFileWe,
    output logic [3:0] alucode,
    output logic [2:0] Lcode,
    output logic [2:0] wdSrcMuxSel,
    output logic       aluSrcMuxSel,
    output logic [1:0] pcSrcMuxSel,
    output logic       dataWe,
    output logic       pcen
);

    //-------------------------------------------------------------------------------
    //  variable declaration
    //-------------------------------------------------------------------------------

    wire [6:0] opcode = instr_code[6:0];
    wire [3:0] r_oper = {instr_code[30], instr_code[14:12]};
    wire [2:0] lisb_oper = instr_code[14:12];

    logic [15:0] out_signal;
    assign {pcen, dataWe, wdSrcMuxSel, aluSrcMuxSel, pcSrcMuxSel, regFileWe, alucode, Lcode} = out_signal;

    typedef enum {
        Fetch,
        Decode,
        Execution,
        MemAcc,
        WriteBack
    } state_e;

    state_e state, next;

    always_ff @(posedge clk, posedge rst) begin : initialize
        if (rst) begin
            state <= Fetch;
        end else begin
            state <= next;
        end
    end

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
                out_signal = {9'b1_0_000_0_00_1, r_oper, 3'bx};
            end
            `L_TYPE: begin
                out_signal = {9'b1_0_001_1_00_1, `ADD, lisb_oper};
            end
            `I_TYPE: begin
                case (lisb_oper)
                    `SLLI, `SRLI, `SRAI:
                    out_signal = {9'b1_0_000_1_00_1, r_oper, 3'bx};
                    default:
                    out_signal = {9'b1_0_000_1_00_1, {1'b0, lisb_oper}, 3'bx};
                endcase

            end
            `S_TYPE: begin
                out_signal = {9'b1_1_000_1_00_0, `ADD, lisb_oper};
            end
            `B_TYPE: begin
                out_signal = {9'b1_0_000_1_01_0, {1'b0, lisb_oper}, 3'bx};
            end
            `LU_TYPE: begin
                out_signal = {9'b1_0_010_1_00_1, 4'b0, 3'bx};
            end
            `AU_TYPE: begin
                out_signal = {9'b1_0_011_1_00_1, 4'b0, 3'bx};
            end
            `J_TYPE: begin
                out_signal = {9'b1_0_100_1_10_1, 4'b0, 3'bx};
            end
            `JL_TYPE: begin
                out_signal = {9'b1_0_100_1_10_1, 4'b0, 3'bx};
            end
        endcase
    end


    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

endmodule
