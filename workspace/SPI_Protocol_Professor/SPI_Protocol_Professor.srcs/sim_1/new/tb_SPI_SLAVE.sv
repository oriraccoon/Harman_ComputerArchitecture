`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/19 11:22:19
// Design Name: 
// Module Name: tb_SPI_SLAVE
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


module tb_SPI_SLAVE(

    );
    // external signals
    logic  SCLK;
    logic  reset;
    logic  MOSI;
    logic MISO;
    logic  SS;

    // internal signals
    logic   write;
    logic   done;
    logic [1:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;


    SPI_SLAVE_Intf dut (
.*
    );


    always #5 SCLK = ~SCLK;

    initial begin
        SCLK = 0; reset = 1; MOSI = 0; SS = 1; rdata = 0;
        #10 reset = 0;

        #100 SS = 0; rdata = 8'd16;
        @(posedge done); SS = 1;
        @(posedge SCLK);
        @(posedge SCLK);
        $finish;
    end
endmodule
