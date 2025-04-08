`timescale 1ns / 1ps

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instr_code,
    input  logic        regFileWe,
    input  logic [ 3:0] alucode,
    output logic [31:0] instr_mem_addr
);

//-------------------------------------------------------------------------------
//  variable declaration
//-------------------------------------------------------------------------------

    logic [31:0] ReadData1, ReadData2;              // Register_File
    logic [31:0] aluResult;                             // ALU
    logic [31:0] pc_in, pc_out;                         // Program_Counter

    assign instr_mem_addr = pc_out;

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



//-------------------------------------------------------------------------------
//  ALU
//-------------------------------------------------------------------------------


    alu U_alu (
        .a(ReadData1),
        .b(ReadData2),
        .alucode(alucode),
        .outport(aluResult)
    );

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------



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
        .a(pc_out),
        .b(32'd4),
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
        for (int i = 0; i < 32; i++) begin
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
            0:       outport = a + b;  // ADD
            1:       outport = a - b;  // SUB
            2:       outport = a & b;  // AND
            3:       outport = a | b;  // OR
            4:       outport = a ^ b;  // XOR
            5:       outport = (a < b) ? 32'd1 : 32'd0;  // SLT
            6:       outport = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;  // SLTU
            7:       outport = a << b;  // SLL
            8:       outport = a >> b;  // SRL
            9:       outport = a >>> b;  // SRA
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

