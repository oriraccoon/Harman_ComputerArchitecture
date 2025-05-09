`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 14:19:01
// Design Name: 
// Module Name: tb_buzzer
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


module tb_buzzer ();
    logic clk;
    logic reset;
    logic [2:0] sw;
    wire buzzer_pulse;


    buzzer dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        sw = 3'b100;
        #10 reset = 0;

        #100000 sw = 3'b101;
        #100000 sw = 3'b110;
        #100000 sw = 3'b111;
        #100000 sw = 3'b000;
        #100000 $finish;
    end

endmodule
