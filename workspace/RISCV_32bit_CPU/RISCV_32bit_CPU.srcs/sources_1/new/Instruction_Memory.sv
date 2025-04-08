module Instruction_Memory (
    input  logic [31:0] instr_mem_addr,
    output logic [31:0] instr_code
);
    
    logic [31:0] rom[0:15];

    initial begin
        // rom[x] = 32'b func7 _ rs2 _ rs1 _ func3 _ rd _ opcode;   // R-Type

        rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1
        rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1
        rom[2] = 32'b0000000_00001_00010_111_00110_0110011; // and x6, x2, x1
        rom[3] = 32'b0000000_00001_00010_110_00111_0110011; // or x7, x2, x1
        rom[4] = 32'b0000000_00001_00010_100_01000_0110011; // xor x8, x2, x1
        rom[5] = 32'b0000000_00001_00010_010_01001_0110011; // SLT x9, x2, x1
        rom[6] = 32'b0000000_00001_00010_011_01010_0110011; // SLTU x10, x2, x1
        rom[7] = 32'b0000000_00001_00010_001_01011_0110011; // SLL x11, x2, x1
        rom[8] = 32'b0000000_00001_00010_101_01100_0110011; // SRL x12, x2, x1
        rom[9] = 32'b0100000_00001_00010_101_01101_0110011; // SRA x13, x2, x1
    end

    assign instr_code = rom[instr_mem_addr[31:2]];

endmodule