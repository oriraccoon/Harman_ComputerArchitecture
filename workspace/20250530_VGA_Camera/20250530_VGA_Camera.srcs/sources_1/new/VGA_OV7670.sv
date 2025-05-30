`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/30 12:31:44
// Design Name: 
// Module Name: VGA_OV7670
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


module VGA_OV7670 (
    // OV7670 Input
    input  logic        PCLK,
    input  logic        reset,
    input  logic        HREF,
    input  logic        VSYNC,
    input  logic [ 7:0] i_data,
    input  logic [16:0] raddr,
    output logic [15:0] rdata
);

    logic [16:0] waddr;
    logic [15:0] wdata;
    logic        wen;

    Mem_Controller U_MEM_CONTROLLER (.*);

    FrameBuffer U_FRAME_BUFFER (.*);


endmodule
