`timescale 1ns / 1ps

class transaction_blink;

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

    constraint c_paddr {PADDR inside {4'h0};}
    constraint c_paddr_o {
        if (PADDR == 0)
        0 < PWDATA;
        400 > PWDATA;        
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, led=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, led);
    endtask  //

endclass  //transaction_blink

interface APB_Slave_Intferface_blink;
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

endinterface  //APB_Slave_Intferface_blink

class generator_blink;
    mailbox #(transaction_blink) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction_blink) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction_blink blink_tr;
        repeat (repeat_counter) begin
            blink_tr = new();  // make instrance
            if (!blink_tr.randomize()) $error("Randomization fail!");
            blink_tr.display("GEN");
            Gen2Drv_mbox.put(blink_tr);
            @(gen_next_event);  // wait a event from driver_blink
        end
    endtask  //
endclass  //generator_blink

class driver_blink;
    virtual APB_Slave_Intferface_blink blink_intf;
    mailbox #(transaction_blink) Gen2Drv_mbox;
    transaction_blink blink_tr;

    function new(virtual APB_Slave_Intferface_blink blink_intf,
                 mailbox#(transaction_blink) Gen2Drv_mbox);
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
            blink_intf.PWRITE  <= 1'b1;
            blink_intf.PENABLE <= 1'b1;
            blink_intf.PSEL    <= 1'b1;
            blink_intf.led    <= blink_tr.led;
            repeat(1000) @(posedge blink_intf.PCLK);
            wait (blink_intf.PREADY == 1'b1);
            @(posedge blink_intf.PCLK);
        end
    endtask  //

endclass  //driver_blink

class monitor_blink;
    mailbox #(transaction_blink) Mon2Scb_mbox;
    virtual APB_Slave_Intferface_blink blink_intf;
    transaction_blink blink_tr;

    function new(virtual APB_Slave_Intferface_blink blink_intf,
                 mailbox#(transaction_blink) Mon2Scb_mbox);
        this.blink_intf = blink_intf;
        this.Mon2Scb_mbox = Mon2Scb_mbox;
    endfunction  //new()

    task run();
        forever begin
            blink_tr = new();
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

endclass  //monitor_blink

class scoreboard_blink;
    mailbox #(transaction_blink) Mon2Scb_mbox;
    transaction_blink blink_tr;
    event gen_next_event;

    function new(mailbox#(transaction_blink) Mon2Scb_mbox, event gen_next_event);
        this.Mon2Scb_mbox   = Mon2Scb_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        forever begin
            Mon2Scb_mbox.get(blink_tr);
            blink_tr.display("SCB");
            if (blink_tr.PWRITE) begin
                
            end
            else begin  // read 
                
            end
            ->gen_next_event;

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

endclass  //scoreboard_blink

class envirnment_blink;
    mailbox #(transaction_blink) Gen2Drv_mbox;
    mailbox #(transaction_blink) Mon2Scb_mbox;

    generator_blink blink_gen;
    driver_blink blink_drv;
    monitor_blink blink_mon;
    scoreboard_blink blink_scb;

    event gen_next_event;

    function new(virtual APB_Slave_Intferface_blink blink_intf);
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
endclass  //envirnment_blink

module tb_blink_sys(

    );

    envirnment_blink blink_env;
    APB_Slave_Intferface_blink blink_intf ();

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
