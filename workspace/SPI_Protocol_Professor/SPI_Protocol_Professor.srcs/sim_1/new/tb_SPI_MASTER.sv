`timescale 1ns / 1ps


module tb_SPI_Master ();

    logic       clk;
    logic       reset;
    logic       cpol;
    logic       cpha;
    logic       start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       done;
    logic       ready;
    logic       SCLK;
    logic       MOSI;
    logic       MISO;
    logic       SS;
    logic       so_done;


    SPI_Master U_M_dut (.*);

    SPI_SLAVE U_S_dut(
        .*
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        repeat(3); @(posedge clk);

        // address byte
        SS = 1;
        @(posedge clk);
        tx_data = 8'b1000_0000; start = 1; cpol = 0; cpha = 0; SS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        // write data byte on 0x01 address

        @(posedge clk);
        tx_data = 8'b0001_0000; start = 1; cpol = 0; cpha = 0; SS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        @(posedge clk);
        tx_data = 8'b0010_0000; start = 1; cpol = 0; cpha = 0; SS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        @(posedge clk);
        tx_data = 8'b0011_0000; start = 1; cpol = 0; cpha = 0; SS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        @(posedge clk);
        tx_data = 8'b0100_0000; start = 1; cpol = 0; cpha = 0; SS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);
        SS = 1;

        // address byte
        SS = 1;
        @(posedge clk);
        tx_data = 8'b0000_0000; start = 1; cpol = 0; cpha = 0; SS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait(so_done == 1);
        @(posedge clk);
        wait(done == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait(so_done == 1);
        @(posedge clk);
        wait(done == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait(so_done == 1);
        @(posedge clk);
        wait(done == 1);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait(so_done == 1);
        @(posedge clk);
        wait(done == 1);
        @(posedge clk);

        SS = 1;

        #200 $finish;
    end
endmodule
