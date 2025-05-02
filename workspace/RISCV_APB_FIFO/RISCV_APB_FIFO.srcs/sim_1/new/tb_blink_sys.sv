`timescale 1ns / 1ps

class transaction;

    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  // dut out data
    logic             PREADY;  // dut out data
    // outport signals
    logic        led;

    constraint c_paddr {PADDR inside {4'h0, 4'h4, 4'h8};}
    constraint c_paddr_o {
        if (PADDR == 0)
        PWDATA inside {1'b0, 1'b1};
        else
        if (PADDR == 4)
        PWDATA < 10;
        else
        if (PADDR == 8) PWDATA < 4'b1111;
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, led=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, led);
    endtask  //

endclass  //transaction

interface APB_Slave_Intferface;
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;  // dut out data
    logic        PREADY;  // dut out data
    // outport signals
    logic        led;

endinterface  //APB_Slave_Intferface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction blink_tr;
        repeat (repeat_counter) begin
            blink_tr = new();  // make instrance
            if (!blink_tr.randomize()) $error("Randomization fail!");
            blink_tr.display("GEN");
            Gen2Drv_mbox.put(blink_tr);
            @(gen_next_event);  // wait a event from driver
        end
    endtask  //
endclass  //generator

class driver;
    virtual APB_Slave_Intferface blink_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction blink_tr;

    function new(virtual APB_Slave_Intferface blink_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.blink_intf = blink_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(blink_tr);
            blink_tr.display("DRV");
            @(posedge blink_intf.PCLK);
            blink_intf.PADDR   <= blink_tr.PADDR;
            blink_intf.PWDATA  <= blink_tr.PWDATA;
            blink_intf.PWRITE  <= blink_tr.PWRITE;
            blink_intf.PENABLE <= 1'b0;
            blink_intf.PSEL    <= 1'b1;
            blink_intf.led    <= blink_tr.led;
            @(posedge blink_intf.PCLK);
            blink_intf.PADDR   <= blink_tr.PADDR;
            blink_intf.PWDATA  <= blink_tr.PWDATA;
            blink_intf.PWRITE  <= blink_tr.PWRITE;
            blink_intf.PENABLE <= 1'b1;
            blink_intf.PSEL    <= 1'b1;
            blink_intf.led    <= blink_tr.led;
            wait (blink_intf.PREADY == 1'b1);
            @(posedge blink_intf.PCLK);
        end
    endtask  //

endclass  //driver

class monitor;
    mailbox #(transaction) Mon2Scb_mbox;
    virtual APB_Slave_Intferface blink_intf;
    transaction blink_tr;

    function new(virtual APB_Slave_Intferface blink_intf,
                 mailbox#(transaction) Mon2Scb_mbox);
        this.blink_intf = blink_intf;
        this.Mon2Scb_mbox = Mon2Scb_mbox;
    endfunction  //new()

    task run();
        forever begin
            blink_tr = new();
            wait (blink_intf.PREADY == 1'b1);
            #1;
            blink_tr.PADDR   = blink_intf.PADDR;
            blink_tr.PWDATA  = blink_intf.PWDATA;
            blink_tr.PWRITE  = blink_intf.PWRITE;
            blink_tr.PENABLE = blink_intf.PENABLE;
            blink_tr.PSEL    = blink_intf.PSEL;
            blink_tr.PRDATA  = blink_intf.PRDATA;  // dut out data
            blink_tr.PREADY  = blink_intf.PREADY;  // dut out data
            blink_tr.led    = blink_intf.led;
            blink_tr.display("Mon");
            Mon2Scb_mbox.put(blink_tr);
            repeat (5) @(posedge blink_intf.PCLK);
        end
    endtask  //run

endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2Scb_mbox;
    transaction blink_tr;
    event gen_next_event;
    logic [3:0] digit [0:3];
    logic [2:0] digit_sel;
    logic [6:0] expect_font;
    logic expect_dot;
    // Reference Model
    logic [31:0] refblinkReg[0:2];
    logic [6:0] refblinkFont[0:9] = '{
        7'h40,  // 1100_0000
        7'h79,  // 1111_1001
        7'h24,  // 1010_0100
        7'h30,  // 1011_0000
        7'h19,  // 1001_1001
        7'h12,  // 1001_0010
        7'h02,  // 1000_0010
        7'h58,  // 1101_1000
        7'h00,  // 1000_0000
        7'h10   // 1001_0000
    };
    logic [9:0] write_cnt = 0;
    logic [9:0] read_cnt = 0;
    logic [9:0] pass_cnt = 0;
    logic [9:0] fail_cnt = 0;
    logic [9:0] total_cnt = 0;
    logic font_pass;
    logic read_pass;
    logic [13:0] fdr;
    logic [3:0] fpr;
    // logic [31:0] RefRData;

    function new(mailbox#(transaction) Mon2Scb_mbox, event gen_next_event);
        this.Mon2Scb_mbox   = Mon2Scb_mbox;
        this.gen_next_event = gen_next_event;
        for (int i = 0; i < 3; i++) begin
            refblinkReg[i] = 0;
        end
        // RefRData = 32'b0;
    endfunction  //new()

    task run();
        font_pass   = 0;
        read_pass   = 0;
        forever begin
            Mon2Scb_mbox.get(blink_tr);
            blink_tr.display("SCB");
            if (blink_tr.PWRITE) begin
                refblinkReg[blink_tr.PADDR[3:2]] = blink_tr.PWDATA;

                write_cnt = write_cnt + 1;

                fdr = refblinkReg[1];
                fpr = refblinkReg[2];

                digit[0] = (fdr % 10);
                digit[1] = (fdr % 100) / 10;
                digit[2] = (fdr % 1000) / 100;
                digit[3] = fdr / 1000;

                case (blink_tr.blinkCom)
                    4'b1110: digit_sel = 0;
                    4'b1101: digit_sel = 1;
                    4'b1011: digit_sel = 2;
                    4'b0111: digit_sel = 3;
                    default: digit_sel = 0;
                endcase

                expect_font = refblinkFont[digit[digit_sel]];
                expect_dot = ~fpr[digit_sel];

                if ({expect_dot,expect_font} == blink_tr.blinkFont[7:0]) begin
                    $display("FONT PASS");
                    font_pass = 1;
                end else begin
                    $display("FONT FAIL");
                    font_pass = 0;
                end           
            end
            else begin  // read 
                if (refblinkReg[blink_tr.PADDR[3:2]] == blink_tr.PRDATA) begin
                    $display("blink Read PASS, %h, %h",
                             refblinkReg[blink_tr.PADDR[3:2]], blink_tr.PRDATA);
                    read_pass = 1;
                end else begin
                    $display("blink Read FAIL, %h, %h",
                             refblinkReg[blink_tr.PADDR[3:2]], blink_tr.PRDATA);
                    read_pass = 0;
                end
                read_cnt = read_cnt + 1;
            end
            ->gen_next_event;

            if (font_pass == 1 | read_pass == 1) begin
                pass_cnt = pass_cnt + 1;
            end else begin
                fail_cnt = fail_cnt + 1;
            end

            total_cnt = total_cnt + 1;
        end

    endtask  //run

    task report();
        $display("===============================");
        $display("==        Final Report       ==");
        $display("===============================");
        $display("      Write Test : %0d", write_cnt);
        $display("      Read Test  : %0d", read_cnt);
        $display("      PASS Test  : %0d", pass_cnt);
        $display("      Fail Test  : %0d", fail_cnt);
        $display("      Total Test : %0d", total_cnt);
        $display("===============================");
        $display("==   test bench is finished  ==");
        $display("===============================");
    endtask  //report

endclass  //scoreboard

class envirnment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2Scb_mbox;

    generator blink_gen;
    driver blink_drv;
    monitor blink_mon;
    scoreboard blink_scb;

    event gen_next_event;

    function new(virtual APB_Slave_Intferface blink_intf);
        Gen2Drv_mbox = new();
        Mon2Scb_mbox = new();
        this.blink_gen = new(Gen2Drv_mbox, gen_next_event);
        this.blink_drv = new(blink_intf, Gen2Drv_mbox);
        this.blink_mon = new(blink_intf, Mon2Scb_mbox);
        this.blink_scb = new(Mon2Scb_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            blink_gen.run(count);
            blink_drv.run();
            blink_mon.run();
            blink_scb.run();
        join_any
            blink_scb.report();
    endtask  //
endclass  //envirnment

module tb_blink_sys(

    );

    envirnment blink_env;
    APB_Slave_Intferface blink_intf ();

    always #5 blink_intf.PCLK = ~blink_intf.PCLK;

    blink_Periph dut (
        // global signal
        .PCLK(blink_intf.PCLK),
        .PRESET(blink_intf.PRESET),
        // APB Interface Signals
        .PADDR(blink_intf.PADDR),
        .PWDATA(blink_intf.PWDATA),
        .PWRITE(blink_intf.PWRITE),
        .PENABLE(blink_intf.PENABLE),
        .PSEL(blink_intf.PSEL),
        .PRDATA(blink_intf.PRDATA),
        .PREADY(blink_intf.PREADY),
        // outport signals
        .led(blink_intf.led)
    );

    initial begin
        blink_intf.PCLK   = 0;
        blink_intf.PRESET = 1;
        #10 blink_intf.PRESET = 0;
        blink_env = new(blink_intf);
        blink_env.run(1000);
        #30;
        $finish;
    end
endmodule
