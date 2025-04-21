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
    logic reset;
    wire [7:0] GPIO;

    

    MCU dut (
        .clk  (clk),
        .reset(reset),
        .GPIO(GPIO)
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #8 reset = 0;
    end
    
endmodule
