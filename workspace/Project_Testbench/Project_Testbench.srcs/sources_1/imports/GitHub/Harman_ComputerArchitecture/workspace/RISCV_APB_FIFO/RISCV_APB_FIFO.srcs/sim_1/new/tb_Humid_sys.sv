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
    logic        dht_io;

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
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, dht_io=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, dht_io);
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
    logic        dht_io;

endinterface  //APB_Slave_Intferface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction dht_tr;
        repeat (repeat_counter) begin
            dht_tr = new();  // make instrance
            if (!dht_tr.randomize()) $error("Randomization fail!");
            dht_tr.display("GEN");
            Gen2Drv_mbox.put(dht_tr);
            @(gen_next_event);  // wait a event from driver
        end
    endtask  //
endclass  //generator

class driver;
    virtual APB_Slave_Intferface dht_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction dht_tr;

    function new(virtual APB_Slave_Intferface dht_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.dht_intf = dht_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(dht_tr);
            dht_tr.display("DRV");
            @(posedge dht_intf.PCLK);
            dht_intf.PADDR   <= dht_tr.PADDR;
            dht_intf.PWDATA  <= dht_tr.PWDATA;
            dht_intf.PWRITE  <= dht_tr.PWRITE;
            dht_intf.PENABLE <= 1'b0;
            dht_intf.PSEL    <= 1'b1;
            dht_intf.dht_io    <= dht_tr.dht_io;
            @(posedge dht_intf.PCLK);
            dht_intf.PADDR   <= dht_tr.PADDR;
            dht_intf.PWDATA  <= dht_tr.PWDATA;
            dht_intf.PWRITE  <= dht_tr.PWRITE;
            dht_intf.PENABLE <= 1'b1;
            dht_intf.PSEL    <= 1'b1;
            dht_intf.dht_io    <= dht_tr.dht_io;
            wait (dht_intf.PREADY == 1'b1);
            @(posedge dht_intf.PCLK);
        end
    endtask  //

endclass  //driver

class monitor;
    mailbox #(transaction) Mon2Scb_mbox;
    virtual APB_Slave_Intferface dht_intf;
    transaction dht_tr;

    function new(virtual APB_Slave_Intferface dht_intf,
                 mailbox#(transaction) Mon2Scb_mbox);
        this.dht_intf = dht_intf;
        this.Mon2Scb_mbox = Mon2Scb_mbox;
    endfunction  //new()

    task run();
        forever begin
            dht_tr = new();
            wait (dht_intf.PREADY == 1'b1);
            #1;
            dht_tr.PADDR   = dht_intf.PADDR;
            dht_tr.PWDATA  = dht_intf.PWDATA;
            dht_tr.PWRITE  = dht_intf.PWRITE;
            dht_tr.PENABLE = dht_intf.PENABLE;
            dht_tr.PSEL    = dht_intf.PSEL;
            dht_tr.PRDATA  = dht_intf.PRDATA;  // dut out data
            dht_tr.PREADY  = dht_intf.PREADY;  // dut out data
            dht_tr.dht_io    = dht_intf.dht_io;
            dht_tr.display("Mon");
            Mon2Scb_mbox.put(dht_tr);
            repeat (5) @(posedge dht_intf.PCLK);
        end
    endtask  //run

endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2Scb_mbox;
    transaction dht_tr;
    event gen_next_event;
    logic [3:0] digit [0:3];
    logic [2:0] digit_sel;
    logic [6:0] expect_font;
    logic expect_dot;
    // Reference Model
    logic [31:0] refdhtReg[0:2];
    logic [6:0] refdhtFont[0:9] = '{
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
            refdhtReg[i] = 0;
        end
        // RefRData = 32'b0;
    endfunction  //new()

    task run();
        font_pass   = 0;
        read_pass   = 0;
        forever begin
            Mon2Scb_mbox.get(dht_tr);
            dht_tr.display("SCB");
            if (dht_tr.PWRITE) begin
                refdhtReg[dht_tr.PADDR[3:2]] = dht_tr.PWDATA;

                write_cnt = write_cnt + 1;

                fdr = refdhtReg[1];
                fpr = refdhtReg[2];

                digit[0] = (fdr % 10);
                digit[1] = (fdr % 100) / 10;
                digit[2] = (fdr % 1000) / 100;
                digit[3] = fdr / 1000;

                case (dht_tr.dhtCom)
                    4'b1110: digit_sel = 0;
                    4'b1101: digit_sel = 1;
                    4'b1011: digit_sel = 2;
                    4'b0111: digit_sel = 3;
                    default: digit_sel = 0;
                endcase

                expect_font = refdhtFont[digit[digit_sel]];
                expect_dot = ~fpr[digit_sel];

                if ({expect_dot,expect_font} == dht_tr.dhtFont[7:0]) begin
                    $display("FONT PASS");
                    font_pass = 1;
                end else begin
                    $display("FONT FAIL");
                    font_pass = 0;
                end           
            end
            else begin  // read 
                if (refdhtReg[dht_tr.PADDR[3:2]] == dht_tr.PRDATA) begin
                    $display("dht Read PASS, %h, %h",
                             refdhtReg[dht_tr.PADDR[3:2]], dht_tr.PRDATA);
                    read_pass = 1;
                end else begin
                    $display("dht Read FAIL, %h, %h",
                             refdhtReg[dht_tr.PADDR[3:2]], dht_tr.PRDATA);
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

    generator dht_gen;
    driver dht_drv;
    monitor dht_mon;
    scoreboard dht_scb;

    event gen_next_event;

    function new(virtual APB_Slave_Intferface dht_intf);
        Gen2Drv_mbox = new();
        Mon2Scb_mbox = new();
        this.dht_gen = new(Gen2Drv_mbox, gen_next_event);
        this.dht_drv = new(dht_intf, Gen2Drv_mbox);
        this.dht_mon = new(dht_intf, Mon2Scb_mbox);
        this.dht_scb = new(Mon2Scb_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            dht_gen.run(count);
            dht_drv.run();
            dht_mon.run();
            dht_scb.run();
        join_any
            dht_scb.report();
    endtask  //
endclass  //envirnment

module tb_Humid_sys(

    );

    envirnment dht_env;
    APB_Slave_Intferface dht_intf ();

    always #5 dht_intf.PCLK = ~dht_intf.PCLK;

    Humidity_Periph dut (
        // global signal
        .PCLK(dht_intf.PCLK),
        .PRESET(dht_intf.PRESET),
        // APB Interface Signals
        .PADDR(dht_intf.PADDR),
        .PWDATA(dht_intf.PWDATA),
        .PWRITE(dht_intf.PWRITE),
        .PENABLE(dht_intf.PENABLE),
        .PSEL(dht_intf.PSEL),
        .PRDATA(dht_intf.PRDATA),
        .PREADY(dht_intf.PREADY),
        // outport signals
        .dht_io(dht_intf.dht_io)
    );

    initial begin
        dht_intf.PCLK   = 0;
        dht_intf.PRESET = 1;
        #10 dht_intf.PRESET = 0;
        dht_env = new(dht_intf);
        dht_env.run(1000);
        #30;
        $finish;
    end
endmodule
