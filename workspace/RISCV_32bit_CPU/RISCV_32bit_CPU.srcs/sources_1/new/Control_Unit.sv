`timescale 1ns / 1ps

module ControlUnit (
    input   logic [31:0] instr_code,
    output  logic        regFileWe,
    output  logic [ 3:0] alucode
);

//-------------------------------------------------------------------------------
//  variable declaration
//-------------------------------------------------------------------------------

    logic [ 3:0] op_analysis;                           // Opcode_Analysis
    
//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
//  Opcode_Analysis
//-------------------------------------------------------------------------------

    opcode_analysis U_Opcode_Analysis(
        .opcode(instr_code[6:0]),
        .op_analysis(op_analysis)
    );

    always_comb begin
        case (op_analysis)
            1: begin
                regFileWe = 1;
                case ({instr_code[30], instr_code[14:12]})
                    4'b0000: alucode = 4'b0;
                    4'b1000: alucode = 4'd1;
                    4'b0111: alucode = 4'd2;
                    4'b0110: alucode = 4'd3;
                    4'b0100: alucode = 4'd4;
                    4'b0010: alucode = 4'd5;
                    4'b0011: alucode = 4'd6;
                    4'b0001: alucode = 4'd7;
                    4'b0101: alucode = 4'd8;
                    4'b1101: alucode = 4'd9;
                    default: alucode = 4'bx;
                endcase
            end
            default: begin
                regFileWe = 0;
                alucode = 4'bx;
            end
        endcase
    end


//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
/*
    typedef enum {
        S0,
        S1,
        S2
    } state_e;

    state_e state, state_next;
    logic [15:0] out_signals;
    logic [31:0] instruction;

    assign {RFSrcMuxSel, alucode, readAddr1, readAddr2, writeAddr, writeEn, outBuf} = out_signals;
    assign {funct7, readAddr1, readAddr2, funct3, writeAddr, opcode} = instruction;

    always_ff @(posedge clk, posedge reset) begin : state_reg
        if (reset) state <= S0;
        else state <= state_next;
    end

    always_comb begin : state_next_machine
        state_next  = state;
        out_signals = 0;
        case (state)
            S0: begin  // R1 = 1
                out_signals = 15'b1_000_000_000_001_1_0;
                state_next  = S1;
            end
            S1: begin  // R2 = 0
                out_signals = 15'b0_000_000_000_010_1_0;
                state_next  = S0;
            end
        endcase
    end */
endmodule

//-------------------------------------------------------------------------------
//  Instance Modules
//-------------------------------------------------------------------------------

module opcode_analysis (
    input logic [6:0] opcode,
    output logic [3:0] op_analysis
);
    
    always_comb begin : analysis
        case (opcode)
            7'b0110011: op_analysis = 1;
            7'b0000011: op_analysis = 2;
            7'b0010011: op_analysis = 3;
            7'b0100011: op_analysis = 4;
            7'b1100011: op_analysis = 5;
            7'b0110111: op_analysis = 6;
            7'b0010111: op_analysis = 7;
            7'b1101111: op_analysis = 8;
            7'b1100111: op_analysis = 9;
            default: op_analysis = 4'bx;
        endcase    
    end

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module instr_separate (
    input  logic [31:0] instr_code,
    output  logic [ 4:0] rs1,
    output  logic [ 4:0] rs2,
    output  logic [ 4:0] rd
);
    
endmodule