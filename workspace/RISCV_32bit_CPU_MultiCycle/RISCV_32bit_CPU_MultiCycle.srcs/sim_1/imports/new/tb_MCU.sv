`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/08 16:27:48
// Design Name: 
// Module Name: tb_MCU
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


module tb_MCU ();

    logic clk;
    logic rst;

    MPU dut (
        .clk  (clk),
        .rst(rst)
    );

     always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst = 1;
        #8 rst = 0;
    end
    
endmodule
