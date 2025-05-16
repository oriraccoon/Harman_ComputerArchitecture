`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/16 17:42:17
// Design Name: 
// Module Name: tb_SPI_TOP
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


module tb_SPI_TOP ();

        // General
        logic clock;
        logic reset;

        // Data
        logic       btn;
        logic [7:0] tx_data;
        wire [7:0] data;

SPI_TOP dut(
    .*
);

always #5 clock = ~clock;

initial begin
    clock = 0; reset = 1; btn = 0; tx_data = 0;
    #10 reset = 0;
    #10 btn = 1; tx_data = 8'b1100_1100;
    #10 btn = 0;
    #1000; $finish;
end

endmodule
