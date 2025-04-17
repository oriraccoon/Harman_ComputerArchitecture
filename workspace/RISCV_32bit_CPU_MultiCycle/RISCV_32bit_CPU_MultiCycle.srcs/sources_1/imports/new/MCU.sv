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


module MPU(
    input  logic       clk,
    input  logic       rst
    );

    logic [31:0] instr_code;
    logic [31:0] instr_mem_addr;
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] rData;
    
    CPU U_CPU ( .* );

    Instruction_Memory U_Instruction_Memory_ROM ( .* );

    Data_Memory U_Data_Memory_RAM ( .* );

endmodule
