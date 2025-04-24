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
    logic      [ 3:0] fndCom;  // dut out data
    logic      [ 7:0] fndFont;  // dut out data

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
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndCom=%h, fndFont=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndCom,
            fndFont);
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
    logic [ 3:0] fndCom;  // dut out data
    logic [ 7:0] fndFont;  // dut out data

endinterface  //APB_Slave_Intferface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new();  // make instrance
            if (!fnd_tr.randomize()) $error("Randomization fail!");
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            @(gen_next_event);  // wait a event from driver
        end
    endtask  //
endclass  //generator

class driver;
    virtual APB_Slave_Intferface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction fnd_tr;

    function new(virtual APB_Slave_Intferface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            fnd_tr.display("DRV");
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= fnd_tr.PWRITE;
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL    <= 1'b1;
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= fnd_tr.PWRITE;
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL    <= 1'b1;
            wait (fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PCLK);
        end
    endtask  //

endclass  //driver

class monitor;
    mailbox #(transaction) Mon2Scb_mbox;
    virtual APB_Slave_Intferface fnd_intf;
    transaction fnd_tr;

    function new(virtual APB_Slave_Intferface fnd_intf,
                 mailbox#(transaction) Mon2Scb_mbox);
        this.fnd_intf = fnd_intf;
        this.Mon2Scb_mbox = Mon2Scb_mbox;
    endfunction  //new()

    task run();
        forever begin
            fnd_tr = new();
            wait (fnd_intf.PREADY == 1'b1);
            #1;
            fnd_tr.PADDR   = fnd_intf.PADDR;
            fnd_tr.PWDATA  = fnd_intf.PWDATA;
            fnd_tr.PWRITE  = fnd_intf.PWRITE;
            fnd_tr.PENABLE = fnd_intf.PENABLE;
            fnd_tr.PSEL    = fnd_intf.PSEL;
            fnd_tr.PRDATA  = fnd_intf.PRDATA;  // dut out data
            fnd_tr.PREADY  = fnd_intf.PREADY;  // dut out data
            fnd_tr.fndCom  = fnd_intf.fndCom;  // dut out data
            fnd_tr.fndFont = fnd_intf.fndFont;  // dut out data
            fnd_tr.display("Mon");
            Mon2Scb_mbox.put(fnd_tr);
            repeat (5) @(posedge fnd_intf.PCLK);
        end
    endtask  //run

endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2Scb_mbox;
    transaction fnd_tr;
    event gen_next_event;
    logic [3:0] digit [0:3];
    logic [2:0] digit_sel;
    logic [6:0] expect_font;
    logic expect_dot;
    // Reference Model
    logic [31:0] refFndReg[0:2];
    logic [6:0] refFndFont[0:9] = '{
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
            refFndReg[i] = 0;
        end
        // RefRData = 32'b0;
    endfunction  //new()

    task run();
        font_pass   = 0;
        read_pass   = 0;
        forever begin
            Mon2Scb_mbox.get(fnd_tr);
            fnd_tr.display("SCB");
            if (fnd_tr.PWRITE) begin
                refFndReg[fnd_tr.PADDR[3:2]] = fnd_tr.PWDATA;

                write_cnt = write_cnt + 1;

                fdr = refFndReg[1];
                fpr = refFndReg[2];

                digit[0] = (fdr % 10);
                digit[1] = (fdr % 100) / 10;
                digit[2] = (fdr % 1000) / 100;
                digit[3] = fdr / 1000;

                case (fnd_tr.fndCom)
                    4'b1110: digit_sel = 0;
                    4'b1101: digit_sel = 1;
                    4'b1011: digit_sel = 2;
                    4'b0111: digit_sel = 3;
                    default: digit_sel = 0;
                endcase

                expect_font = refFndFont[digit[digit_sel]];
                expect_dot = ~fpr[digit_sel];

                if ({expect_dot,expect_font} == fnd_tr.fndFont[7:0]) begin
                    $display("FONT PASS");
                    font_pass = 1;
                end else begin
                    $display("FONT FAIL");
                    font_pass = 0;
                end           
            end
            else begin  // read 
                if (refFndReg[fnd_tr.PADDR[3:2]] == fnd_tr.PRDATA) begin
                    $display("FND Read PASS, %h, %h",
                             refFndReg[fnd_tr.PADDR[3:2]], fnd_tr.PRDATA);
                    read_pass = 1;
                end else begin
                    $display("FND Read FAIL, %h, %h",
                             refFndReg[fnd_tr.PADDR[3:2]], fnd_tr.PRDATA);
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

    generator fnd_gen;
    driver fnd_drv;
    monitor fnd_mon;
    scoreboard fnd_scb;

    event gen_next_event;

    function new(virtual APB_Slave_Intferface fnd_intf);
        Gen2Drv_mbox = new();
        Mon2Scb_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox);
        this.fnd_mon = new(fnd_intf, Mon2Scb_mbox);
        this.fnd_scb = new(Mon2Scb_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
            fnd_scb.report();
    endtask  //
endclass  //envirnment

module tb_fndController_APB_Periph ();

    envirnment fnd_env;
    APB_Slave_Intferface fnd_intf ();

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FndController_Periph dut (
        // global signal
        .PCLK(fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),
        // APB Interface Signals
        .PADDR(fnd_intf.PADDR),
        .PWDATA(fnd_intf.PWDATA),
        .PWRITE(fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),
        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // outport signals
        .fndCom(fnd_intf.fndCom),
        .fndFont(fnd_intf.fndFont)
    );

    initial begin
        fnd_intf.PCLK   = 0;
        fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(1000);
        #30;
        $finish;
    end
endmodule


/*`timescale 1ns / 1ps

class transaction;
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand bit        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;
    logic             PREADY;
    // export signals
    logic      [ 3:0] fndComm;
    logic      [ 7:0] fndFont;
    logic      [ 1:0] sel;

    constraint c_paddr {PADDR inside {4'h0, 4'h4, 4'h8};}
    constraint c_waddr {PWDATA < 10000;}
    constraint c_paddr_0 {
        if (PADDR == 0)
        PWDATA inside {1'b0, 1'b1};
        else
        if (PADDR == 4)
        PWDATA < 10000;
        else
        if (PADDR == 8) PWDATA inside {1'b0, 1'b1};
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndCom=%h, fndFont=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY,
            fndComm, fndFont);
    endtask  //display
endclass  //transaction

interface APB_Slave_Interface;
    logic        PCLK;
    logic        PRESET;

    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    // export signals
    logic [ 3:0] fndComm;
    logic [ 7:0] fndFont;
    logic [ 1:0] sel;

endinterface  //APB_Slave_Interface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new();  // make instance
            if (!fnd_tr.randomize())
                $error("Randomization fail");  // 랜덤값 생성
            fnd_tr.display("GEN");  // 상태 출력
            Gen2Drv_mbox.put(fnd_tr);  // dirver로 전달
            @(gen_next_event);  // wait a event from driver, 다음 신호 대기
        end
    endtask  //run
endclass  //generater

class driver;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            fnd_tr.display("DRV");
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR <= fnd_tr.PADDR;
            fnd_intf.PWDATA <= fnd_tr.PWDATA;
            fnd_intf.PWRITE <= fnd_tr.PWRITE;
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL <= 1'b1;
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR <= fnd_tr.PADDR;
            fnd_intf.PWDATA <= fnd_tr.PWDATA;
            fnd_intf.PWRITE <= fnd_tr.PWRITE;
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL <= 1'b1;
            wait (fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
        end
    endtask  //run
endclass  //dirver

class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual APB_Slave_Interface fnd_intf;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Mon2SCB_mbox);
        this.fnd_intf = fnd_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
    endfunction  //new()

    task run();
        forever begin
            fnd_tr = new();
            @(posedge fnd_intf.PREADY);
            #1;
            fnd_tr.PADDR   = fnd_intf.PADDR;
            fnd_tr.PWDATA  = fnd_intf.PWDATA;
            fnd_tr.PWRITE  = fnd_intf.PWRITE;
            fnd_tr.PENABLE = fnd_intf.PENABLE;
            fnd_tr.PSEL    = fnd_intf.PSEL;
            fnd_tr.PRDATA  = fnd_intf.PRDATA;
            fnd_tr.PREADY  = fnd_intf.PREADY;
            fnd_tr.fndComm = fnd_intf.fndComm;
            fnd_tr.fndFont = fnd_intf.fndFont;
            fnd_tr.sel     = fnd_intf.sel;
            Mon2SCB_mbox.put(fnd_tr);
            fnd_tr.display("MON");
            @(posedge fnd_intf.PCLK);
        end
    endtask  //run
endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction fnd_tr;
    event gen_next_event;

    // reference model
    logic [3:0] digit[3:0];
    logic [31:0] refFndReg[0:2];
    logic [7:0] refFndFont[0:15] = '{
        8'hC0,
        8'hF9,
        8'hA4,
        8'hB0,
        8'h99,
        8'h92,
        8'h82,
        8'hF8,
        8'h80,
        8'h90,
        8'h88,
        8'h83,
        8'hC6,
        8'hA1,
        8'h86,
        8'h8E
    };
    logic [9:0] write_cnt = 0;
    logic [9:0] read_cnt = 0;
    logic [9:0] pass_cnt = 0;
    logic [9:0] fail_cnt = 0;
    logic [9:0] total_cnt = 0;

    logic font_pass;
    logic enable_pass;
    logic read_pass;

    function new(mailbox#(transaction) Mon2SCB_mbox, event gen_next_event);
        this.Mon2SCB_mbox   = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;
        for (int i = 0; i < 3; i++) begin
            refFndReg[i] = 0;
        end
    endfunction  //new()

    task run();
        font_pass   = 0;
        enable_pass = 0;
        read_pass   = 0;
        forever begin
            Mon2SCB_mbox.get(fnd_tr);
            fnd_tr.display("SCB");
            if (fnd_tr.PWRITE) begin  // write mode
                refFndReg[fnd_tr.PADDR[3:2]] = fnd_tr.PWDATA;
                //reference register updata
                digit[0] = refFndReg[1] % 10;
                digit[1] = (refFndReg[1] / 10) % 10;
                digit[2] = (refFndReg[1] / 100) % 10;
                digit[3] = (refFndReg[1] / 1000) % 10;

                write_cnt = write_cnt + 1;

                if ({~refFndReg[2][fnd_tr.sel],refFndFont[digit[fnd_tr.sel]][6:0]} == fnd_tr.fndFont) begin
                    $display("FND Font PASS, %h, %h", {
                             ~refFndReg[2][fnd_tr.sel],
                             refFndFont[digit[fnd_tr.sel]][6:0]},
                             fnd_tr.fndFont);
                    font_pass = 1;
                end else begin
                    $display("FND Font FAIL, %h, %h", {
                             ~refFndReg[2][fnd_tr.sel],
                             refFndFont[digit[fnd_tr.sel]][6:0]},
                             fnd_tr.fndFont);
                    font_pass = 0;
                end
                if (refFndReg[0] == 0) begin  // en = 0: fndCom == 4'b1111;
                    if (4'hf == fnd_tr.fndComm) begin
                        $display("FND EnableComport PASS");
                        enable_pass = 1;
                    end else begin
                        $display("FND Enable FAIL");
                        enable_pass = 0;
                    end
                end else begin  // en == 1;
                    if (4'b1 << fnd_tr.sel == ~fnd_tr.fndComm[3:0])
                        $display(
                            "FND Comport PASS, %h, %h",
                            4'b1 << fnd_tr.sel,
                            ~fnd_tr.fndComm[3:0]
                        );
                    else
                        $display(
                            "FND Comport FAIL, %h, %h",
                            4'b1 << fnd_tr.sel,
                            ~fnd_tr.fndComm[3:0]
                        );
                end
            end else begin  // read 
                if (refFndReg[fnd_tr.PADDR[3:2]] == fnd_tr.PRDATA) begin
                    $display("FND Read PASS, %h, %h",
                             refFndReg[fnd_tr.PADDR[3:2]], fnd_tr.PRDATA);
                    read_pass = 1;
                end else begin
                    $display("FND Read FAIL, %h, %h",
                             refFndReg[fnd_tr.PADDR[3:2]], fnd_tr.PRDATA);
                    read_pass = 0;
                end
                read_cnt = read_cnt + 1;
            end
            ->gen_next_event;

            if ((font_pass == 1 & enable_pass == 1) | read_pass == 1) begin
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

class envirnment;  // Generator 와 Driver 연결하고 동시에 실행 
                   // generator 가 만든 트랜잭션을 driver가 처리
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;

    generator              fnd_gen;
    driver                 fnd_drv;
    monitor                fnd_mon;
    scoreboard             fnd_scb;
    event                  gen_next_event;

    function new(virtual APB_Slave_Interface fnd_intf);
        this.Gen2Drv_mbox = new();
        this.Mon2SCB_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox);
        this.fnd_mon = new(fnd_intf, Mon2SCB_mbox);
        this.fnd_scb = new(Mon2SCB_mbox, gen_next_event);
    endfunction

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
            fnd_scb.report();
    endtask  //run
endclass  //envirnment

module tb_fndDot ();

    envirnment fnd_env;
    APB_Slave_Interface fnd_intf(); // interface는 new를 만들어주지 않음

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FND_Periph dut (
        // global signal
        .PCLK  (fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),

        .PADDR  (fnd_intf.PADDR),
        .PWDATA (fnd_intf.PWDATA),
        .PWRITE (fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),

        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // inport signals
        .fndComm(fnd_intf.fndComm),
        .fndFont(fnd_intf.fndFont),
        .sel(fnd_intf.sel)
    );

    initial begin
        fnd_intf.PCLK   = 0;
        fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);  // envirnment instance 생성
        fnd_env.run(1000);  // 10번 시도
        #30;
        $display("finished");
        $finish;
    end
endmodule*/