`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/26 17:48:07
// Design Name: 
// Module Name: tb_PWM
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


module tb_PWM ();
    logic clk;
    logic reset;
    logic [7:0] duty_rate;
    logic led;

    PWM dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; duty_rate = 0;
        #10 reset = 0;
        #50 duty_rate = 50;
        #1000000
        $finish;
    end

endmodule
