`timescale 1ns / 1ps

class transaction_ultra;

    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  // dut out data
    logic             PREADY;  // dut out data
    // outport signals
    logic        echo;
    logic        trig;
    rand logic [7:0] i_distance;

    constraint c_paddr {PADDR inside {4'h0, 4'h4};}
    constraint c_dis {
        10 < i_distance;
        i_distance < 50;
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, i_distance=%d",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, i_distance);
    endtask  //

endclass  //transaction_ultra

interface APB_Slave_Intferface_ultra;
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
    logic        echo;
    logic        trig;
    logic [7:0] i_distance;

endinterface  //APB_Slave_Intferface_ultra

class generator_ultra;
    mailbox #(transaction_ultra) Gen2Drv_mbox_ultra;
    event gen_next_event;

    function new(mailbox#(transaction_ultra) Gen2Drv_mbox_ultra, event gen_next_event);
        this.Gen2Drv_mbox_ultra   = Gen2Drv_mbox_ultra;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction_ultra ultra_tr;
        repeat (repeat_counter) begin
            ultra_tr = new();  // make instrance
            if (!ultra_tr.randomize()) $error("Randomization fail!");
            ultra_tr.display("GEN");
            Gen2Drv_mbox_ultra.put(ultra_tr);
            @(gen_next_event);  // wait a event from driver_ultra
        end
    endtask  //
endclass  //generator_ultra

class driver_ultra;
    virtual APB_Slave_Intferface_ultra ultra_intf;
    mailbox #(transaction_ultra) Gen2Drv_mbox_ultra;
    transaction_ultra ultra_tr;
    event mon_next_event;

    function new(virtual APB_Slave_Intferface_ultra ultra_intf,
                 mailbox#(transaction_ultra) Gen2Drv_mbox_ultra,
                 event mon_next_event);
        this.ultra_intf = ultra_intf;
        this.Gen2Drv_mbox_ultra = Gen2Drv_mbox_ultra;
        this.mon_next_event = mon_next_event;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox_ultra.get(ultra_tr);
            ultra_tr.display("DRV");
            @(posedge ultra_intf.PCLK);
            ultra_intf.PADDR   <= 4'h0;
            ultra_intf.PWDATA  <= 32'b1;
            ultra_intf.PWRITE  <= 1'b1;
            ultra_intf.PENABLE <= 1'b1;
            ultra_intf.PSEL    <= 1'b1;
            ultra_intf.i_distance    <= ultra_tr.i_distance;
            wait (ultra_intf.PREADY == 1'b1);
            wait (ultra_intf.trig == 1'b1);
            wait (ultra_intf.trig == 1'b0);
            #10700;
            ultra_intf.echo    <= 1'b1;
            repeat(ultra_tr.i_distance * 100 * 58) @(posedge ultra_intf.PCLK);
            #30000;
            ultra_intf.echo    <= 1'b0;
            @(posedge ultra_intf.PCLK);
            @(posedge ultra_intf.PCLK);
            @(posedge ultra_intf.PCLK);
            ultra_intf.PADDR   <= 4'h4;
            ultra_intf.PWDATA  <= 32'b0;
            ultra_intf.PWRITE  <= 1'b0;
            ultra_intf.PENABLE <= 1'b1;
            ultra_intf.PSEL    <= 1'b1;
            @(posedge ultra_intf.PCLK);
            ->mon_next_event;
            
        end
    endtask  //

endclass  //driver_ultra

class monitor_ultra;
    mailbox #(transaction_ultra) Mon2Scb_mbox_ultra;
    virtual APB_Slave_Intferface_ultra ultra_intf;
    transaction_ultra ultra_tr;
    event mon_next_event;

    function new(virtual APB_Slave_Intferface_ultra ultra_intf,
                 mailbox#(transaction_ultra) Mon2Scb_mbox_ultra,
                 event mon_next_event);
        this.ultra_intf = ultra_intf;
        this.Mon2Scb_mbox_ultra = Mon2Scb_mbox_ultra;
        this.mon_next_event = mon_next_event;
    endfunction  //new()

    task run();
        forever begin
            ultra_tr = new();
            @(mon_next_event);
            #1;
            ultra_tr.PADDR   = ultra_intf.PADDR;
            ultra_tr.PWDATA  = ultra_intf.PWDATA;
            ultra_tr.PWRITE  = ultra_intf.PWRITE;
            ultra_tr.PENABLE = ultra_intf.PENABLE;
            ultra_tr.PSEL    = ultra_intf.PSEL;
            ultra_tr.PRDATA  = ultra_intf.PRDATA;  // dut out data
            ultra_tr.PREADY  = ultra_intf.PREADY;  // dut out data
            ultra_tr.i_distance = ultra_intf.i_distance;
            ultra_tr.display("Mon");
            Mon2Scb_mbox_ultra.put(ultra_tr);
            repeat (5) @(posedge ultra_intf.PCLK);
        end
    endtask  //run

endclass  //monitor_ultra

class scoreboard_ultra;
    mailbox #(transaction_ultra) Mon2Scb_mbox_ultra;
    transaction_ultra ultra_tr;
    event gen_next_event;

    int read_cnt, pass_cnt, fail_cnt, total_cnt;
    bit read_pass;
    int expected_distance;

    function new(mailbox#(transaction_ultra) Mon2Scb_mbox_ultra, event gen_next_event);
        this.Mon2Scb_mbox_ultra   = Mon2Scb_mbox_ultra;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        forever begin
            Mon2Scb_mbox_ultra.get(ultra_tr);
            ultra_tr.display("SCB");

            if (!ultra_tr.PWRITE) begin
                read_cnt++;
                expected_distance = ultra_tr.i_distance;

                if (ultra_tr.PRDATA[$clog2(400)-1:0] == expected_distance) begin
                    $display("[SCB] Read PASS! Expected = %0d, Got = %0d", expected_distance, ultra_tr.PRDATA[7:0]);
                    pass_cnt++;
                end else begin
                    $display("[SCB] Read FAIL! Expected = %0d, Got = %0d", expected_distance, ultra_tr.PRDATA[7:0]);
                    fail_cnt++;
                end

                total_cnt++;
                
                ->gen_next_event;
            end

        end
    endtask

    task report();
        $display("===============================");
        $display("==        Final Report       ==");
        $display("===============================");
        $display("      Read Test  : %0d", read_cnt);
        $display("      PASS Test  : %0d", pass_cnt);
        $display("      Fail Test  : %0d", fail_cnt);
        $display("      Total Test : %0d", total_cnt);
        $display("===============================");
        $display("==   test bench is finished  ==");
        $display("===============================");
    endtask  //report

endclass  //scoreboard_ultra

class envirnment_ultra;
    mailbox #(transaction_ultra) Gen2Drv_mbox_ultra;
    mailbox #(transaction_ultra) Mon2Scb_mbox_ultra;

    generator_ultra ultra_gen;
    driver_ultra ultra_drv;
    monitor_ultra ultra_mon;
    scoreboard_ultra ultra_scb;

    event gen_next_event;
    event mon_next_event;

    function new(virtual APB_Slave_Intferface_ultra ultra_intf);
        Gen2Drv_mbox_ultra = new();
        Mon2Scb_mbox_ultra = new();
        this.ultra_gen = new(Gen2Drv_mbox_ultra, gen_next_event);
        this.ultra_drv = new(ultra_intf, Gen2Drv_mbox_ultra, mon_next_event);
        this.ultra_mon = new(ultra_intf, Mon2Scb_mbox_ultra, mon_next_event);
        this.ultra_scb = new(Mon2Scb_mbox_ultra, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            ultra_gen.run(count);
            ultra_drv.run();
            ultra_mon.run();
            ultra_scb.run();
        join_any
            ultra_scb.report();
    endtask  //
endclass  //envirnment_ultra

module tb_Ultra_sys(

    );

    envirnment_ultra ultra_env;
    APB_Slave_Intferface_ultra ultra_intf ();

    always #5 ultra_intf.PCLK = ~ultra_intf.PCLK;

    Ultrasonic_Periph dut (
        // global signal
        .PCLK(ultra_intf.PCLK),
        .PRESET(ultra_intf.PRESET),
        // APB Interface Signals
        .PADDR(ultra_intf.PADDR),
        .PWDATA(ultra_intf.PWDATA),
        .PWRITE(ultra_intf.PWRITE),
        .PENABLE(ultra_intf.PENABLE),
        .PSEL(ultra_intf.PSEL),
        .PRDATA(ultra_intf.PRDATA),
        .PREADY(ultra_intf.PREADY),
        // outport signals
        .echo(ultra_intf.echo),
        .trig(ultra_intf.trig)
    );

    initial begin
        ultra_intf.PCLK   = 0;
        ultra_intf.PRESET = 1;
        #10 ultra_intf.PRESET = 0;
        ultra_env = new(ultra_intf);
        ultra_env.run(50);
        #30;
        $finish;
    end
endmodule
