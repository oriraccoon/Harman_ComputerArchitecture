`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/02 10:53:18
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


module tb ();

reg clk, reset;
reg [2:0] ctrl;

top_counter_up_down dut(
    .clk(clk),
    .reset(reset),
    .mode(ctrl)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    ctrl = 0;
    #10 reset = 0;
    #100 ctrl = 3'b010;
    #1000000 ctrl = 3'b100;
    #100 ctrl = 3'b110;
    #100 ctrl = 3'b010;
end

endmodule
