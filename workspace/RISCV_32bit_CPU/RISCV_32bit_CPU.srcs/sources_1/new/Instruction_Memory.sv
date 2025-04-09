module Instruction_Memory (
    input  logic [31:0] instr_mem_addr,
    output logic [31:0] instr_code
);
    
    logic [31:0] rom[0:15];

    initial begin
        // rom[x] = 32'b func7 _ rs2 _ rs1 _ func3 _ rd _ opcode;   // R-Type
        // rom[x] = 32'b imm12 _ rs _ func3 _ rd _ opcode;   // L-Type
        // rom[x] = 32'b imm12 _ rs _ func3 _ rd _ opcode;   // I-Type
        // rom[x] = 32'b func7 _ shamt _ rs1 _ func3 _ rd _ opcode;   // I-Type
        // rom[x] = 32'b imm7 _ rs2 _ rs1 _ f3 _ imm5 _ opcode;     // S-Type

        rom[0] = 32'b0000000_00001_00010_000_00100_0110011; // add x4, x2, x1       // 5ns      reg
        rom[1] = 32'b0100000_00001_00010_000_00101_0110011; // sub x5, x2, x1       // 25ns     reg

        rom[2] = 32'b0000000_00010_00000_010_01000_0100011; // sw x2, 8(x0);        // 35ns     ram

        rom[3] = 32'b000000010000_00000_010_00011_0000011; // lw x3, 16, x0;        // 45ns     reg
        rom[4] = 32'b000000010000_00000_000_00111_0000011; // lb x7, 16, x0;        // 55ns     reg
        rom[5] = 32'b000000110000_00000_000_01000_0010011; // ADDI x8, 48, x0;      // 65ns     reg
        rom[6] = 32'b000000110000_00000_010_01001_0010011; // SLTI x9, 48, x0;      // 75ns     reg
        rom[7] = 32'b000000110000_00000_011_01010_0010011; // SLTIU x10, 48, x0;    // 85ns     reg
        rom[8] = 32'b000000110000_00010_100_01011_0010011; // XORI x11, 48, x2;     // 95ns     reg
        rom[9] = 32'b000000110000_00010_110_01100_0010011; // ORI x12, 48, x2;      // 105ns     reg
        rom[10] = 32'b000000110000_00010_111_01101_0010011; // ANDI x13, 48, x2;    // 115ns     reg
        rom[11] = 32'b000000110000_00100_001_01110_0010011; // SLLI x14, 48, x4;    // 125ns     reg
        rom[12] = 32'b000000110000_00100_101_01111_0010011; // SRLI x15, 48, x4;    // 135ns     reg
        rom[13] = 32'b000000110000_00100_101_10000_0010011; // SRAI x16, 48, x4;    // 145ns     reg

        rom[14] = 32'b0000000_00011_00000_000_10000_0100011; // sb x3, 16(x0);       // 155ns     ram
    end

    assign instr_code = rom[instr_mem_addr[31:2]];

endmodule