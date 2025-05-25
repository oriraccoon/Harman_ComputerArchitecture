`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/25 16:06:10
// Design Name: 
// Module Name: SPI_Top
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


module SPI_Top(
    input            clk,
    input            rst,
    input            cpol,
    input            cpha,
    input            start,
    input            ss,
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    output       done,
    output       ready
);

wire SS, MISO, MOSI, SCLK;

SPI_Master U_M (
    // global signals
    // internal signals
    // external port
    .clk(clk),
    .rst(rst),
    .cpol(cpol),
    .cpha(cpha),
    .start(start),
    .ss(ss),
    .tx_data(tx_data),
    .rx_data(rx_data),
    .done(done),
    .ready(ready),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .SS(SS)
);

SPI_Slave U_S (
    // global signals
    .clk(clk),
    .rst(rst),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .SS(SS)
);


endmodule
