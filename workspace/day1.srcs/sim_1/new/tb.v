`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/01 11:07:50
// Design Name: 
// Module Name: tb
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


module tb;

reg clk;
reg rst;
reg mod;

test1 dut(
    .clk(clk),
    .rst(rst),
    .mod(mod)
);

always #1 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    mod = 0;
    #10 rst = 0;
    #1000000 mod = 1;
    #1000000 mod = 0;
    

end

endmodule
