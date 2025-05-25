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
    logic       SS;
    logic       so_done;


    spi_top dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;

        repeat (3);
        @(posedge clk);

        repeat (5) begin
            SS = 1;
            @(posedge clk);
            tx_data = 8'b1000_0000;
            start = 1;
            cpol = 0;
            cpha = 0;
            SS = 0;
            @(posedge clk);
            start = 0;
            repeat (799) @(posedge clk);
            @(posedge clk);

            // write data byte on 0x01 address

            @(posedge clk);
            tx_data = 8'b1111_1111;
            start = 1;
            cpol = 0;
            cpha = 0;
            SS = 0;
            @(posedge clk);
            start = 0;
            repeat (799) @(posedge clk);
            @(posedge clk);

            // address byte
            SS = 1;
            @(posedge clk);
            tx_data = 8'b0000_0000;
            start = 1;
            cpol = 0;
            cpha = 0;
            SS = 0;
            @(posedge clk);
            start = 0;
            repeat (799) @(posedge clk);
            @(posedge clk);

            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            repeat (701) @(posedge clk);
            @(posedge clk);
            repeat (97) @(posedge clk);
            @(posedge clk);

            // spi_item.print(uvm_default_line_printer);
            
            @(posedge clk);
            tx_data = 8'b0001_0000;
        end

        #200 $finish;
    end
endmodule
