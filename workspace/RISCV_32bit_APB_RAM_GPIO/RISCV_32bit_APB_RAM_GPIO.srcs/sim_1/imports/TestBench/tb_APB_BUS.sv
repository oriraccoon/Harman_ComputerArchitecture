`timescale 1ns / 1ps


module tb_APB_BUS();

    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL0;
    logic        PSEL1;
    logic        PSEL2;
    logic        PSEL3;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic        PREADY0;
    logic        PREADY1;
    logic        PREADY2;
    logic        PREADY3;
    //Internal Interface Signals
    logic        transfer; // trigger signal
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;  // 1: write, 0: read


    APB_Master U_APB_Master(
        .*
    );

    APB_Slave U_Slave_Periph0(
        .*,
        .PSEL(PSEL0),
        .PRDATA(PRDATA0),
        .PREADY(PREADY0)
    );

    APB_Slave U_Slave_Periph1(
        .*,
        .PSEL(PSEL1),
        .PRDATA(PRDATA1),
        .PREADY(PREADY1)
    );

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK = 0;
        PRESET = 1;
        #10 PRESET = 0;

        @(posedge PCLK);
        #1 addr = 32'h1000_1000;
        write = 1;
        wdata = 10;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        @(posedge PCLK);
        #1 addr = 32'h1000_1004;
        write = 1;
        wdata = 11;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        @(posedge PCLK);
        #1 addr = 32'h1000_1008;
        write = 1;
        wdata = 12;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        @(posedge PCLK);
        #1 addr = 32'h1000_100C;
        write = 1;
        wdata = 13;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        //read
        @(posedge PCLK);
        #1 addr = 32'h1000_1000;
        write = 0;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        @(posedge PCLK);
        #1 addr = 32'h1000_1004;
        write = 0;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        @(posedge PCLK);
        #1 addr = 32'h1000_1008;
        write = 0;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        @(posedge PCLK);
        #1 addr = 32'h1000_100C;
        write = 0;
        transfer = 1;
        @(posedge PCLK);
        #1 transfer = 0;
        wait(ready == 1'b1);
        @(posedge PCLK);
        #30; $finish;
    end
endmodule
