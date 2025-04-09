`timescale 1ns / 1ps
`include "defined.sv"

module DataPath (
    input logic        clk,
    input logic        reset,
    input logic [31:0] instr_code,
    input logic        regFileWe,
    input logic [ 3:0] alucode,
    input logic        aluSrcMuxSel_rs1,
    input logic        aluSrcMuxSel_rs2,
    input logic [31:0] rData,

    output logic [31:0] instr_mem_addr,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData
);

    //-------------------------------------------------------------------------------
    //  variable declaration
    //-------------------------------------------------------------------------------

    logic [31:0] ReadData1, ReadData2;  // Register_File
    logic [31:0] pc_in, pc_out;  // Program_Counter
    logic [31:0] immExt, aluSrcMuxOut_rs1, aluSrcMuxOut_rs2;  // Mux
    logic [31:0] aluResult;  // ALU


    assign instr_mem_addr = pc_out;
    assign dataAddr = aluResult;
    assign dataWData = ReadData2;

    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------



    //-------------------------------------------------------------------------------
    //  Register_File
    //-------------------------------------------------------------------------------


    RegFile U_RegFile (
        .clk(clk),
        .readAddr1(instr_code[19:15]),
        .readAddr2(instr_code[24:20]),
        .writeAddr(instr_code[11:7]),
        .writeEn(regFileWe),
        .wData(aluResult),
        .rData1(ReadData1),
        .rData2(ReadData2)
    );

    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

    mux2x1 U_ALUsrcMux_rs1 (
        .sel(aluSrcMuxSel_rs1),
        .x0 (ReadData1),
        .x1 (rData),
        .y  (aluSrcMuxOut_rs1)
    );

    mux2x1 U_ALUsrcMux_rs2 (
        .sel(aluSrcMuxSel_rs2),
        .x0 (ReadData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut_rs2)
    );

    //-------------------------------------------------------------------------------
    //  ALU
    //-------------------------------------------------------------------------------


    alu U_alu (
        .a(aluSrcMuxOut_rs1),
        .b(aluSrcMuxOut_rs2),
        .alucode(alucode),
        .outport(aluResult)
    );

    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

    extend U_ImmExtend (
        .instr_code(instr_code),
        .immExt(immExt)
    );

    //-------------------------------------------------------------------------------
    //  Program_Counter
    //-------------------------------------------------------------------------------

    register U_Program_Counter (
        .clk(clk),
        .reset(reset),
        .en(1),
        .d(pc_in),
        .q(pc_out)
    );

    adder U_PC_Adder (
        .a  (pc_out),
        .b  (32'd4),
        .sum(pc_in)
    );

    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

endmodule



//-------------------------------------------------------------------------------
//  Instance Modules
//-------------------------------------------------------------------------------

module RegFile (
    input  logic        clk,
    input  logic [ 4:0] readAddr1,
    input  logic [ 4:0] readAddr2,
    input  logic [ 4:0] writeAddr,
    input  logic        writeEn,
    input  logic [31:0] wData,
    output logic [31:0] rData1,
    output logic [31:0] rData2
);

    logic [31:0] mem[0:2**5-1];

    initial begin
        mem[0] = 0;
        mem[1] = 1;
        for (int i = 2; i < 32; i++) begin
            mem[i] = 10 + i;
        end
    end

    always_ff @(posedge clk) begin : write
        if (writeEn) mem[writeAddr] <= wData;
    end

    assign rData1 = (readAddr1 != 5'b0) ? mem[readAddr1] : 32'b0;
    assign rData2 = (readAddr2 != 5'b0) ? mem[readAddr2] : 32'b0;

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);

    always_ff @(posedge clk, posedge reset) begin : register
        if (reset) q <= 0;
        else begin
            if (en) q <= d;
        end
    end

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [ 3:0] alucode,
    output logic [31:0] outport
);

    always_comb begin : alu_comb
        case (alucode)
            `ADD: outport = a + b;  // ADD
            `SUB: outport = a - b;  // SUB
            `SLL: outport = a << b;  // SLL
            `SRL: outport = a >> b;  // SRL
            `SRA: outport = $signed(a) >>> b;  // SRA
            `SLT: outport = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;  // SLT
            `SLTU: outport = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;  // SLTU
            `XOR: outport = a ^ b;  // XOR
            `OR: outport = a | b;  // OR
            `AND: outport = a & b;  // AND
            default: outport = 32'bx;
        endcase
    end

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] sum
);

    assign sum = a + b;

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module mux2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);

    always_comb begin
        case (sel)
            0: y = x0;
            1: y = x1;
            default: y = 32'bx;
        endcase
    end

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module extend (
    input  logic [31:0] instr_code,
    output logic [31:0] immExt
);

    wire [6:0] opcode = instr_code[6:0];

    always_comb begin
        case (opcode)
            `L_TYPE, `I_TYPE: begin
                immExt = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            `S_TYPE: begin
                immExt = {
                    {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
                };
            end
            default: immExt = 32'bx;
        endcase
    end

endmodule
