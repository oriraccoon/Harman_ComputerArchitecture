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
    logic dataWe_reg, regFileWe_reg, aluSrcMuxSel_reg, dataWe_next, regFileWe_next, aluSrcMuxSel_next, dataWe_sig, regFileWe_sig, aluSrcMuxSel_sig;
    logic [1:0] pcSrcMuxSel_reg, pcSrcMuxSel_next, pcSrcMuxSel_sig;
    logic [2:0] wdSrcMuxSel_reg, Lcode_reg, wdSrcMuxSel_next, Lcode_next, wdSrcMuxSel_sig, Lcode_sig;
    logic [3:0] alucode_reg, alucode_next, alucode_sig;


    logic [14:0] out_signal;
    assign {dataWe_sig, wdSrcMuxSel_sig, aluSrcMuxSel_sig, pcSrcMuxSel_sig, regFileWe_sig, alucode_sig, Lcode_sig} = out_signal;

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
            dataWe_reg <= 1'bx;
            regFileWe_reg <= 1'bx;
            aluSrcMuxSel_reg <= 1'bx;
            pcSrcMuxSel_reg <= 2'bx;
            wdSrcMuxSel_reg <= 3'bx;
            Lcode_reg <= 3'bx;
            alucode_reg <= 4'bx;
        end else begin
            state <= next;
            dataWe_reg <= dataWe_next;
            regFileWe_reg <= regFileWe_next;
            aluSrcMuxSel_reg <= aluSrcMuxSel_next;
            pcSrcMuxSel_reg <= pcSrcMuxSel_next;
            wdSrcMuxSel_reg <= wdSrcMuxSel_next;
            Lcode_reg <= Lcode_next;
            alucode_reg <= alucode_next;
        end
    end

    assign {dataWe, wdSrcMuxSel, aluSrcMuxSel, pcSrcMuxSel, regFileWe, alucode, Lcode} = 
    {dataWe_reg, wdSrcMuxSel_reg, aluSrcMuxSel_reg, pcSrcMuxSel_reg, regFileWe_reg, alucode_reg, Lcode_reg};

    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

    //-------------------------------------------------------------------------------
    //  Opcode_Analysis
    //-------------------------------------------------------------------------------

    always_comb begin
        next = state;
        pcen = 1'b0;
        dataWe_next = 1'bx;
        regFileWe_next = 1'bx;
        aluSrcMuxSel_next = 1'bx;
        pcSrcMuxSel_next = 2'bx;
        wdSrcMuxSel_next = 3'bx;
        Lcode_next = 3'bx;
        alucode_next = 4'bx;
        case (state)
            Fetch: begin
                pcen = 1;
                next = Decode;
            end
            Decode: begin
                next = Execution;
            end
            Execution: begin
                case (opcode)
                    `R_TYPE: begin
                        next = Fetch;
                        regFileWe_next = regFileWe_sig;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = 3'bx;
                    end
                    `L_TYPE: begin
                        next = MemAcc;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = Lcode_sig;
                    end
                    `I_TYPE: begin
                        next = Fetch;
                        regFileWe_next = regFileWe_sig;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = 3'bx;
                    end
                    `S_TYPE: begin
                        regFileWe_next = regFileWe_sig;
                        next = MemAcc;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = Lcode_sig;
                    end
                    `B_TYPE: begin
                        regFileWe_next = regFileWe_sig;
                        next = Fetch;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = 3'bx;
                    end
                    `LU_TYPE: begin
                        regFileWe_next = regFileWe_sig;
                        next = Fetch;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = 3'bx;
                    end
                    `AU_TYPE: begin
                        regFileWe_next = regFileWe_sig;
                        next = Fetch;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = 3'bx;
                    end
                    `J_TYPE: begin
                        regFileWe_next = regFileWe_sig;
                        next = Fetch;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = 3'bx;
                    end
                    `JL_TYPE: begin
                        regFileWe_next = regFileWe_sig;
                        next = Fetch;
                        aluSrcMuxSel_next = aluSrcMuxSel_sig;
                        wdSrcMuxSel_next = wdSrcMuxSel_sig;
                        pcSrcMuxSel_next = pcSrcMuxSel_sig;
                        alucode_next = alucode_sig;
                        Lcode_next = 3'bx;
                    end
                endcase
            end
            MemAcc: begin
                dataWe_next = dataWe_sig;
                case (opcode)
                    `L_TYPE: begin
                        next = WriteBack;
                    end
                    `S_TYPE: begin
                        next = Fetch;
                    end
                endcase
            end
            WriteBack: begin
                next = Fetch;
                wdSrcMuxSel_next = wdSrcMuxSel_sig;
            end
        endcase
    end

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
                    `SLLI, `SRLI, `SRAI:
                    out_signal = {8'b0_000_1_00_1, r_oper, 3'bx};
                    default:
                    out_signal = {8'b0_000_1_00_1, {1'b0, lisb_oper}, 3'bx};
                endcase

            end
            `S_TYPE: begin
                out_signal = {8'b1_000_1_00_0, `ADD, lisb_oper};
            end
            `B_TYPE: begin
                out_signal = {8'b0_000_1_01_0, {1'b0, lisb_oper}, 3'bx};
            end
            `LU_TYPE: begin
                out_signal = {8'b0_010_1_00_1, 4'b0, 3'bx};
            end
            `AU_TYPE: begin
                out_signal = {8'b0_011_1_00_1, 4'b0, 3'bx};
            end
            `J_TYPE: begin
                out_signal = {8'b0_100_1_10_1, 4'b0, 3'bx};
            end
            `JL_TYPE: begin
                out_signal = {8'b0_100_1_10_1, 4'b0, 3'bx};
            end
        endcase
    end


    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

endmodule
