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
    logic       CS;

    assign MISO = MOSI; //MISO 테스트

    SPI_Master U_dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; CS = 1;
        reset = 1;
        #10;
        reset = 0;

        repeat(3); @(posedge clk);

        // address byte
        @(posedge clk);
        tx_data = 8'h01; start = 1; cpol = 0; cpha = 0; CS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        // write data byte on 0x01 address
        @(posedge clk);
        tx_data = 8'h55; start = 1; cpol = 0; cpha = 0; CS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        @(posedge clk);
        tx_data = 8'haa; start = 1; cpol = 0; cpha = 1;  CS = 0;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);

        @(posedge clk);
        tx_data = 8'hab; start = 1;  cpol = 1; cpha = 1;
        @(posedge clk);
        start = 0;
        wait(done == 1);
        @(posedge clk);
        CS = 1;


        #200 $finish;
    end
endmodule
