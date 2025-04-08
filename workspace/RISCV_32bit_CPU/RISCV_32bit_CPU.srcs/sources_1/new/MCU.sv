`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/08 16:19:05
// Design Name: 
// Module Name: MCU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MCU(
    input  logic       clk,
    input  logic       reset
    );

    logic [31:0] instr_code;
    logic [31:0] instr_mem_addr;

    CPU U_CPU ( .* );

    Instruction_Memory U_Instruction_Memory ( .* );

endmodule
