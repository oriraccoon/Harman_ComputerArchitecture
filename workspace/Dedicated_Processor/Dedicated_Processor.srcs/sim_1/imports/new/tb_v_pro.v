`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/06 23:40:09
// Design Name: 
// Module Name: tb_v_pro
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


module tb_v_pro(

    );
    
    reg clk, rst;
    reg [3:0] repeat_num;
    reg [2:0] start_num;
    
    Dedicate_Processor dut(
    .clk(clk),
    .rst(rst),
    .repeat_num(repeat_num),
    .start_num(start_num)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        rst = 1;
        repeat_num = 0;
        start_num = 0;
        #10
        rst = 0;
        repeat_num = 11;
        start_num = 0;
    end
    
endmodule
