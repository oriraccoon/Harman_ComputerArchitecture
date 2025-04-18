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
    logic dataWe_sig, regFileWe_sig, aluSrcMuxSel_sig;
    logic [1:0] pcSrcMuxSel_sig;
    logic [2:0] wdSrcMuxSel_sig, Lcode_sig;
    logic [3:0] alucode_sig;

    logic [14:0] out_signal, internal_signals;
    assign {dataWe_sig, wdSrcMuxSel_sig, aluSrcMuxSel_sig, pcSrcMuxSel_sig, regFileWe_sig, alucode_sig, Lcode_sig} = out_signal;
    assign {dataWe, wdSrcMuxSel, aluSrcMuxSel, pcSrcMuxSel, regFileWe, alucode, Lcode} = internal_signals;
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
        internal_signals = 15'b0;
        pcen = 1'b0;
        next = state;
        case (state)
            Fetch: begin
                internal_signals = 15'b0;
                pcen = 1'b1;
                next = Decode;
            end
            Decode: begin
                internal_signals = 15'b0;
                next = Execution;
            end
            Execution: begin
                // internal_signals = {1'b0, 3'b0, 1'b0, 2'b0, 1'b0, alucode_sig, Lcode_sig};
                // {dataWe, wdSrcMuxSel, aluSrcMuxSel, pcSrcMuxSel, regFileWe, alucode, Lcode}
                case (opcode)
                    `R_TYPE, `I_TYPE, `B_TYPE, `LU_TYPE, `AU_TYPE, `J_TYPE, `JL_TYPE: begin
                        next = Fetch;
                        internal_signals = out_signal;
                    end
                    `L_TYPE: begin
                        next = MemAcc;
                        internal_signals = {1'b0, wdSrcMuxSel_sig, aluSrcMuxSel_sig, 2'b0, 1'b0, `ADD, Lcode_sig};
                    end
                    `S_TYPE: begin
                        next = MemAcc;
                        internal_signals = {1'b0, 3'b0, aluSrcMuxSel_sig, 2'b0, 1'b0, alucode_sig, Lcode_sig};
                    end
                    default: begin
                        next = Fetch;
                        internal_signals = 15'b0;
                    end
                endcase
            end
            MemAcc: begin
                case (opcode)
                    `L_TYPE: begin
                        next = WriteBack;
                        internal_signals = {1'b0, wdSrcMuxSel_sig, aluSrcMuxSel_sig, 2'b0, 1'b0, alucode_sig, Lcode_sig};
                    end
                    `S_TYPE: begin
                        internal_signals = out_signal;
                        next = Fetch;
                    end
                    default: begin
                        next = Fetch;
                        internal_signals = 15'b0;
                    end
                endcase
            end
            WriteBack: begin
                next = Fetch;
                internal_signals = out_signal;
            end
            default: begin
                next = Fetch;
                internal_signals = 15'b0;
                pcen = 1'b0;
            end
        endcase
    end

    always_comb begin
        // {dataWe, wdSrcMuxSel, aluSrcMuxSel, pcSrcMuxSel, regFileWe, alucode, Lcode}
        out_signal = 0;  // 초기화
        case (opcode)
            `R_TYPE: begin
                out_signal = {1'b0, 3'b000, 1'b0, 2'b00, 1'b1, r_oper, 3'b0};
            end
            `L_TYPE: begin
                out_signal = {1'b0, 3'b001, 1'b1, 2'b00, 1'b1, `ADD, lisb_oper};
            end
            `I_TYPE: begin
                case (lisb_oper)
                    `SLLI, `SRLI: begin
                        out_signal = {1'b0, 3'b000, 1'b1, 2'b00, 1'b1, r_oper, 3'b0};
                    end
                    default: begin
                        out_signal = {1'b0, 3'b000, 1'b1, 2'b00, 1'b1, {1'b0, lisb_oper}, 3'b0};
                    end
                endcase
            end
            `S_TYPE: begin
                out_signal = {1'b1, 3'b000, 1'b1, 2'b00, 1'b0, `ADD, lisb_oper};
            end
            `B_TYPE: begin
                out_signal = {1'b0, 3'b000, 1'b0, 2'b01, 1'b0, {1'b0, lisb_oper}, 3'b0};
            end
            `LU_TYPE: begin
                out_signal = {1'b0, 3'b010, 1'b1, 2'b00, 1'b1, 4'b0, 3'b0};
            end
            `AU_TYPE: begin
                out_signal = {1'b0, 3'b011, 1'b1, 2'b00, 1'b1, 4'b0, 3'b0};
            end
            `J_TYPE: begin
                out_signal = {1'b0, 3'b100, 1'b1, 2'b10, 1'b1, 4'b0, 3'b0};
            end
            `JL_TYPE: begin
                out_signal = {1'b0, 3'b100, 1'b1, 2'b10, 1'b1, 4'b0, 3'b0};
            end
            default: begin
                out_signal = 0;
            end
        endcase
    end



    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

endmodule
