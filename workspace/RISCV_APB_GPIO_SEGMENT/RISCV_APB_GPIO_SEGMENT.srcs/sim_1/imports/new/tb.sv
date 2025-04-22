`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/22 11:17:55
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


`timescale 1ns / 1ps

module tb_RV32I ();

    logic clk;
    logic reset;
    wire [3:0] an;
    wire [7:0] seg;
    wire  [7:0] GPIOC;
    wire  [7:0] GPIOD;
    reg k;
    reg y;
    reg [7:0] GPIBK;
    reg [7:0] GPIBY;

    MCU dut (.*);

    assign GPIOC = k ? GPIBK : 8'bz;
    assign GPIOD = y ? GPIBY : 8'bz;

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1;
        k = 0;
        y = 0;
        GPIBK = 8'b0;
        #10 reset = 0;
        y = 1;
        GPIBY = 8'b0000_1111;
        #100;
        #100 $finish;
    end
endmodule
