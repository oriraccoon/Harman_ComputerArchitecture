`timescale 1ns / 1ps
`include "defined.sv"

module DataPath (
    input logic        clk,
    input logic        reset,
    input logic [31:0] instr_code,
    input logic        regFileWe,
    input logic [ 3:0] alucode,
    input logic [ 2:0] Lcode,
    input logic [ 2:0] wdSrcMuxSel,
    input logic        aluSrcMuxSel,
    input logic [ 1:0] pcSrcMuxSel,
    input logic [31:0] rData,

    output logic [31:0] instr_mem_addr,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData
);

    //-------------------------------------------------------------------------------
    //  variable declaration
    //-------------------------------------------------------------------------------

    logic [31:0] ReadData1, ReadData2;  // Register_File
    logic [31:0] pc_in, pc_out, branch_Add_pc;  // Program_Counter
    logic [31:0] immExt, wdSrcMuxOut, aluSrcMuxOut, pcSrcMuxOut, jump_pc_out;  // Mux
    logic [31:0] aluResult;  // ALU
    logic [31:0] Lmux_data, Smux_data;  // MUX


    assign instr_mem_addr = pc_out;
    assign dataAddr = aluResult;
    assign dataWData = Smux_data;

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
        .wData(wdSrcMuxOut),
        .rData1(ReadData1),
        .rData2(ReadData2)
    );

    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

    LScode_analysis U_Lcode_analysis (
        .Lcode(Lcode),
        .rdata(rData),
        .data (Lmux_data)
    );

    LScode_analysis U_Scode_analysis (
        .Lcode(Lcode),
        .rdata(ReadData2),
        .data (Smux_data)
    );

    mux5x1 U_wdsrcMux (
        .sel(wdSrcMuxSel),
        .x0 (aluResult),
        .x1 (Lmux_data),
        .x2 (immExt),
        .x3 (branch_Add_pc),
        .x4 (pc_in),
        .y  (wdSrcMuxOut)
    );

    mux2x1 U_ALUsrcMux (
        .sel(aluSrcMuxSel),
        .x0 (ReadData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut)
    );

    //-------------------------------------------------------------------------------
    //  ALU
    //-------------------------------------------------------------------------------


    alu U_alu (
        .a(ReadData1),
        .b(aluSrcMuxOut),
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
        .d(pcSrcMuxOut),
        .q(pc_out)
    );

    adder U_PC_Adder (
        .a  (pc_out),
        .b  (32'd4),
        .sum(pc_in)
    );

    jump_pc U_jump_pc (
        .instr_code(instr_code),
        .rs1(ReadData1),
        .pc_in(pc_out),
        .immExt(immExt),
        .pc_out(jump_pc_out)
    );

    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------

    branch_Add U_branch_Add (
        .instr_code(instr_code),
        .rs1(ReadData1),
        .rs2(ReadData2),
        .pc_in(pc_out),
        .immExt(aluSrcMuxOut),
        .pc_out(branch_Add_pc)
    );

    mux3x1 U_pcsrcMux (
        .sel(pcSrcMuxSel),
        .x0 (pc_in),
        .x1 (branch_Add_pc),
        .x2 (jump_pc_out),
        .y  (pcSrcMuxOut)
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

    logic [31:0] mem[0:11];
    initial begin
        mem[0] = 0;
        mem[1] = 1;
        mem[2] = 2;
        mem[3] = 2;
        mem[4] = 3;
        mem[5] = -3;
        mem[6] = -4;
        for (int i = 7; i < 12; i++) begin
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
            `SLTU:
            outport = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;  // SLTU
            `XOR: outport = a ^ b;  // XOR
            `OR: outport = a | b;  // OR
            `AND: outport = a & b;  // AND
            default: outport = 32'bx;
        endcase
    end

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module branch_Add (
    input  logic [31:0] instr_code,
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    input  logic [31:0] pc_in,
    input  logic [31:0] immExt,
    output logic [31:0] pc_out
);

    wire [6:0] opcode = instr_code[6:0];
    wire [2:0] func3 = instr_code[14:12];

    always_comb begin
        case (opcode)
            `B_TYPE: begin
                case (func3)
                    `BEQ: begin
                        if (rs1 == rs2) pc_out = pc_in + immExt;
                        else pc_out = pc_in + 4;
                    end
                    `BNE: begin
                        if (rs1 != rs2) pc_out = pc_in + immExt;
                        else pc_out = pc_in + 4;
                    end
                    `BLT: begin
                        if ($signed(rs1) < $signed(rs2))
                            pc_out = pc_in + immExt;
                        else pc_out = pc_in + 4;
                    end
                    `BGE: begin
                        if ($signed(rs1) >= $signed(rs2))
                            pc_out = pc_in + immExt;
                        else pc_out = pc_in + 4;
                    end
                    `BLTU: begin
                        if (rs1 < rs2) pc_out = pc_in + immExt;
                        else pc_out = pc_in + 4;
                    end
                    `BGEU: begin
                        if (rs1 >= rs2) pc_out = pc_in + immExt;
                        else pc_out = pc_in + 4;
                    end
                    default: pc_out = 32'bx;
                endcase
            end
            `AU_TYPE: begin
                pc_out = pc_in + immExt;
            end
            default: pc_out = 32'bx;
        endcase
        
    end

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module jump_pc (
    input  logic [31:0] instr_code,
    input  logic [31:0] rs1,
    input  logic [31:0] pc_in,
    input  logic [31:0] immExt,
    output logic [31:0] pc_out
);
    
    wire [6:0] opcode = instr_code[6:0];
    wire [2:0] func3 = instr_code[14:12];

    always_comb begin
        case (opcode)
            `J_TYPE: begin
                pc_out = pc_in + immExt;
            end
            `JL_TYPE: begin
                pc_out = rs1 + immExt;
            end     
            default: pc_out = 32'bx;
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

module mux3x1 (
    input  logic [ 1:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    output logic [31:0] y
);

    always_comb begin
        case (sel)
            0: y = x0;
            1: y = x1;
            2: y = x2;
            default: y = 32'bx;
        endcase
    end

endmodule

module mux5x1 (
    input  logic [ 2:0] sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);

    always_comb begin
        case (sel)
            0: y = x0;
            1: y = x1;
            2: y = x2;
            3: y = x3;
            4: y = x4;
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
    wire [2:0] func3 = instr_code[14:12];

    always_comb begin
        case (opcode)
            `L_TYPE: begin
                case (func3)
                    `LBU, `LHU: immExt = {20'b0, instr_code[31:20]};
                    default: immExt = {{20{instr_code[31]}}, instr_code[31:20]};
                endcase

            end
            `I_TYPE: begin
                case (func3)
                    `SLLI, `SRLI:
                    immExt = {{27{instr_code[31]}}, instr_code[24:20]};
                    `SLTIU: immExt = {20'b0, instr_code[31:20]};
                    default: immExt = {{20{instr_code[31]}}, instr_code[31:20]};
                endcase
            end
            `S_TYPE: begin
                immExt = {
                    {20{instr_code[31]}},
                    instr_code[31:25],
                    instr_code[11:7]
                };
            end
            `B_TYPE: begin
                case (func3)
                    `BLTU, `BGEU:
                    immExt = {
                        19'b0,
                        instr_code[31],
                        instr_code[7],
                        instr_code[30:25],
                        instr_code[11:8],
                        1'b0
                    };
                    default:
                    immExt = {
                        {19{instr_code[31]}},
                        instr_code[31],
                        instr_code[7],
                        instr_code[30:25],
                        instr_code[11:8],
                        1'b0
                    };
                endcase

            end
            `LU_TYPE, `AU_TYPE: begin
                immExt = instr_code[31:12] << 12;
            end
            `J_TYPE: begin
                immExt = {
                    {11{instr_code[31]}},
                    instr_code[31],
                    instr_code[19:12],
                    instr_code[20],
                    instr_code[30:21],
                    1'b0
                };
            end
            `JL_TYPE: begin
                immExt = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            default: immExt = 32'bx;
        endcase
    end

endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------

module LScode_analysis (
    input  logic [ 2:0] Lcode,
    input  logic [31:0] rdata,
    output logic [31:0] data
);
    always_comb begin
        case (Lcode)
            `LB: data = {{24{rdata[7]}}, rdata[7:0]};
            `LH: data = {{16{rdata[15]}}, rdata[15:0]};
            `LW: data = rdata;
            `LBU: data = {24'b0, rdata[7:0]};
            `LHU: data = {16'b0, rdata[15:0]};
            default: data = rdata;
        endcase
    end
endmodule

//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
