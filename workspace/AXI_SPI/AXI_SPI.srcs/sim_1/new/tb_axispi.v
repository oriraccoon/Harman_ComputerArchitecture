`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/20 16:44:20
// Design Name: 
// Module Name: tb_axispi
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


module tb_axispi ();

    reg btn;
    reg clk;
    reg reset;
    reg [7:0] sw;
    wire [7:0] led;


    design_1_wrapper dut (
        btn,
        clk,
        led,
        reset,
        sw
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        btn = 0;
        sw = 0;
        #10 reset = 0;
        #10 btn = 1;
        sw = 8;
        #2000 $finish;
    end



endmodule
