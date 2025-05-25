`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/25 16:05:57
// Design Name: 
// Module Name: tb_SPI
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


module tb_SPI ();

    logic       clk;
    logic       rst;
    logic       cpol;
    logic       cpha;
    logic       start;
    logic       ss;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       done;
    logic       ready;

    SPI_Top dut (.*);

    logic [7:0] data;

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; cpol = 0; cpha = 0; data = 8'b0001_0000;
        #10 rst = 0;
        repeat (3) @(posedge clk);

        repeat(5) begin
            ss = 1;
            @(posedge clk);
            tx_data = 8'b1000_0000;
            start = 1;
            ss = 0;
            @(posedge clk);
            start = 0;
            wait (done);
            @(posedge clk);


            @(posedge clk);
            tx_data = data;
            start = 1;
            @(posedge clk);
            start = 0;
            wait (done);
            @(posedge clk);


            @(posedge clk);
            ss = 1;
            @(posedge clk);
            tx_data = 8'b0000_0000;
            start = 1;
            ss = 0;
            @(posedge clk);
            start = 0;
            wait (done);
            @(posedge clk);


            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            wait (done);
            @(posedge clk);

            data = data + 8'b0001_0000;
        end

        #200 $finish;

    end



endmodule
