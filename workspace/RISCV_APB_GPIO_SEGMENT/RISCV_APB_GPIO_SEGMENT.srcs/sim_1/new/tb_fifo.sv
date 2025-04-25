`timescale 1ns / 1ps

module tb_fifo ();

    logic       clk;
    logic       reset;
    // write side
    logic [7:0] wdata;
    logic       wr_en;
    logic       full;
    // read side
    logic [7:0] rdata;
    logic       rd_en;
    logic       empty;

    FIFO DUT (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1;
        #10 reset = 0; rd_en = 0;
        @(posedge clk); #1; wdata = 1; wr_en = 1;
        @(posedge clk); #1; wdata = 2; wr_en = 1;
        @(posedge clk); #1; wdata = 3; wr_en = 1;
        @(posedge clk); #1; wdata = 4; wr_en = 1;
        @(posedge clk); #1; wdata = 5; wr_en = 1;
        @(posedge clk); #1; wr_en = 0;
        @(posedge clk); #1; rd_en = 1;
        @(posedge clk); #1; rd_en = 1;
        @(posedge clk); #1; rd_en = 1;
        @(posedge clk); #1; rd_en = 1;
        @(posedge clk); #1; rd_en = 1;
        #20; $finish;
    end


endmodule
