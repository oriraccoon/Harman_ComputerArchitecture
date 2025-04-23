/*`timescale 1ns / 1ps

class transaction;

    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  // dut out data
    logic             PREADY;  // dut out data
    // inport signals
    logic      [ 3:0] fndCom;  // dut out data
    logic      [ 7:0] fndFont;  // dut out data

    constraint c_paddr {
        PADDR inside {4'h0, 4'h4, 4'h8};
    }  // 이거 중에 하나 쓸거임
    constraint c_wdata {PWDATA < 10;}

    task display(string name);
        $display(
            "[%s] PADDR = %h, PWDATA = %h, PWRITE = %h, PENABLE = %h, PSEL = %h, PRDATA = %h, PREADY = %h, fndCom = %h, fndFont = %h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndCom,
            fndFont);
    endtask  //display

endclass

interface APB_Slave_Interface;
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
    // inport signals
    logic [ 3:0] fndCom;  // dut out data
    logic [ 7:0] fndFont;  // dut out data

endinterface  //APB_Slave_Interface

class generator;

    mailbox #(transaction) Gen2Drv_mbox;
    event                  gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new();
            if (!fnd_tr.randomize()) begin
                $error("Randomization Fail!!!!!!!!!!!!!!!");
            end
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            @(gen_next_event);  // wait an event from driver
        end
    endtask  //run
endclass  //generator

class driver;

    virtual APB_Slave_Interface fnd_interface;
    mailbox #(transaction)      Gen2Drv_mbox;
    event                       gen_next_event;
    transaction                 fnd_tr;

    function new(virtual APB_Slave_Interface fnd_interface,
                 mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.fnd_interface  = fnd_interface;
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            @(posedge fnd_interface.PCLK);
            fnd_interface.PADDR   <= fnd_tr.PADDR;
            fnd_interface.PWDATA  <= fnd_tr.PWDATA;
            fnd_interface.PWRITE  <= 1'b1;
            fnd_interface.PENABLE <= 1'b0;
            fnd_interface.PSEL    <= 1'b1;
            @(posedge fnd_interface.PCLK);
            fnd_interface.PADDR   <= fnd_tr.PADDR;
            fnd_interface.PWDATA  <= fnd_tr.PWDATA;
            fnd_interface.PWRITE  <= 1'b1;
            fnd_interface.PENABLE <= 1'b1;
            fnd_interface.PSEL    <= 1'b1;
            wait (fnd_interface.PREADY == 1'b1);
            @(posedge fnd_interface.PCLK);
            @(posedge fnd_interface.PCLK);
            ->gen_next_event;  // event trigger
        end
    endtask  //run
endclass  //driver

class scoreboard;
    mailbox #(transaction) Sb2Mon_mbox;
    logic [3:0] expected_bcd;
    logic [7:0] expected_seg;

    function new(mailbox#(transaction) Sb2Mon_mbox);
        this.Sb2Mon_mbox = Sb2Mon_mbox;
    endfunction

    // BCD to 7-segment decoder
    function automatic logic [7:0] bcd2seg(logic [3:0] bcd);
        case (bcd)
            4'd0: return 8'b1100_0000;
            4'd1: return 8'b1111_1001;
            4'd2: return 8'b1010_0100;
            4'd3: return 8'b1011_0000;
            4'd4: return 8'b1001_1001;
            4'd5: return 8'b1001_0010;
            4'd6: return 8'b1000_0010;
            4'd7: return 8'b1101_1000;
            4'd8: return 8'b1000_0000;
            4'd9: return 8'b1001_0000;
            default: return 8'b1111_1111;
        endcase
    endfunction

    task run(int repeat_counter);
        transaction tr;
        repeat (repeat_counter) begin
            Sb2Mon_mbox.get(tr);

            expected_bcd = tr.PWDATA[3:0];  // 하위 4비트만 사용
            expected_seg = bcd2seg(expected_bcd);

            if (expected_seg == tr.fndFont) begin
                tr.display("SB");
                $display("PASS");
            end else begin
                tr.display("SB");
                $display("FAIL");
            end
        end
    endtask
endclass


class monitor;
    mailbox #(transaction)      Sb2Mon_mbox;
    virtual APB_Slave_Interface fnd_interface;
    transaction                 fnd_tr;

    function new(virtual APB_Slave_Interface fnd_interface,
                 mailbox#(transaction) Sb2Mon_mbox);
        this.fnd_interface  = fnd_interface;
        this.Sb2Mon_mbox   = Sb2Mon_mbox;
    endfunction  //new()

    task run();
        forever begin
            wait (fnd_interface.PREADY == 1'b1);
            @(posedge fnd_interface.PCLK);
            @(posedge fnd_interface.PCLK);
            fnd_tr = new();
            fnd_tr.PWDATA = fnd_interface.PWDATA;
            fnd_tr.PREADY = fnd_interface.PREADY;
            fnd_tr.fndCom = fnd_interface.fndCom;
            fnd_tr.fndFont = fnd_interface.fndFont;
            Sb2Mon_mbox.put(fnd_tr);
        end
    endtask  //run
endclass  //monitor

class envirnment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Sb2Mon_mbox;
    generator              fnd_gen;
    driver                 fnd_drv;
    scoreboard             fnd_sb;
    monitor                fnd_mon;
    event                  gen_next_event;

    function new(virtual APB_Slave_Interface fnd_interface);
        Gen2Drv_mbox = new();
        Sb2Mon_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_interface, Gen2Drv_mbox, gen_next_event);
        this.fnd_sb = new(Sb2Mon_mbox);
        this.fnd_mon = new(fnd_interface, Sb2Mon_mbox);
    endfunction  //new()

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
        join_none
        ;
        fork
            fnd_mon.run();
            fnd_sb.run(count);
        join_any
        ;
    endtask  //run
endclass  //envirnment

module tb_top ();
    envirnment fnd_env;
    APB_Slave_Interface fnd_interface ();


    FndController_Periph DUT (
        // global signal
        .PCLK   (fnd_interface.PCLK),
        .PRESET (fnd_interface.PRESET),
        // APB Interface Signals
        .PADDR  (fnd_interface.PADDR),
        .PWDATA (fnd_interface.PWDATA),
        .PWRITE (fnd_interface.PWRITE),
        .PENABLE(fnd_interface.PENABLE),
        .PSEL   (fnd_interface.PSEL),
        .PRDATA (fnd_interface.PRDATA),
        .PREADY (fnd_interface.PREADY),
        // inport signals
        .fndCom (fnd_interface.fndCom),
        .fndFont(fnd_interface.fndFont)
    );

    always #5 fnd_interface.PCLK = ~fnd_interface.PCLK;

    initial begin
        fnd_interface.PCLK   = 0;
        fnd_interface.PRESET = 1;
        @(posedge fnd_interface.PCLK);
        fnd_interface.PRESET = 0;
        fnd_env = new(fnd_interface);
        fnd_env.run(10);
        @(posedge fnd_interface.PCLK);
        @(posedge fnd_interface.PCLK);
        @(posedge fnd_interface.PCLK);
        $finish;
    end
endmodule
*/