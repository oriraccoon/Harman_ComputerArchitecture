`timescale 1ns / 1ps

module tb_FIFO_Periph ();

    logic        PCLK;
    logic        PRESET;
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic [7:0] rdata;

    FIFO_Periph dut (.*);

    always #5 PCLK = ~PCLK;


    initial begin
        PCLK    = 0;
        PRESET  = 1;
        PADDR   = 0;
        PWDATA  = 0;
        PWRITE  = 0;
        PENABLE = 0;
        PSEL    = 0;

        #20 PRESET = 0;

        $display("[WRITE] Writing 0x11 to FIFO");
        apb_write(4'h4, 32'h00000011);

        $display("[WRITE] Writing 0x22 to FIFO");
        apb_write(4'h4, 32'h00000022);

        $display("[WRITE] Writing 0x33 to FIFO");
        apb_write(4'h4, 32'h00000033);

        $display("[WRITE] Writing 0x44 to FIFO");
        apb_write(4'h4, 32'h00000044);

        @(posedge PCLK);
        $display("[READ]] Reading from FIFO");
        apb_read(4'h8, rdata);
        $display("Read Data = %h", rdata);

        apb_read(4'h8, rdata);
        $display("Read Data = %h", rdata);

        apb_read(4'h8, rdata);
        $display("Read Data = %h", rdata);

        apb_read(4'h8, rdata);
        $display("Read Data = %h", rdata);

        #50;
        $finish;
    end

    // APB Write Task
    task apb_write(input [3:0] addr, input [31:0] data);
        @(posedge PCLK);
        PADDR   <= addr;
        PWDATA  <= data;
        PWRITE  <= 1;
        PSEL    <= 1;
        PENABLE <= 0;

        @(posedge PCLK);
        PENABLE <= 1;

        wait (PREADY == 1);
        @(posedge PCLK);

        PADDR   <= 0;
        PWDATA  <= 0;
        PWRITE  <= 0;
        PSEL    <= 0;
        PENABLE <= 0;
    endtask

    // APB Read Task
    task apb_read(input [3:0] addr, output [7:0] data_out);
        @(posedge PCLK);
        PADDR   <= addr;
        PWRITE  <= 0;
        PSEL    <= 1;
        PENABLE <= 0;

        @(posedge PCLK);
        PENABLE <= 1;

        wait (PREADY == 1);
        @(posedge PCLK);
        data_out = PRDATA[7:0];

        PADDR   <= 0;
        PWRITE  <= 0;
        PSEL    <= 0;
        PENABLE <= 0;
    endtask

endmodule
