`timescale 1ns / 1ps

class transaction_humi;

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
    rand logic [7:0] humidity_deci;
    rand logic [7:0] humidity_inte;
    rand logic [7:0] temperature_deci;
    rand logic [7:0] temperature_inte;
    rand logic sel_data;

    constraint c_data_rand {
        5 < humidity_deci;
        5 < humidity_inte;
        5 < temperature_deci;
        5 < temperature_inte;
        30 > humidity_deci;
        30 > humidity_inte;
        30 > temperature_deci;
        30 > temperature_inte;
    }    

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, humi=%h, temp=%h, sel_data(0:temp, 1:humi)=%d",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, {humidity_deci, humidity_inte}, {temperature_deci, temperature_inte}, sel_data);
    endtask  //

endclass  //transaction_humi

interface APB_Slave_Intferface_humi;
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
    wire        dht_io;
    logic dht_io_drv; 
    logic dht_io_en;
    logic [7:0] humidity_deci;
    logic [7:0] humidity_inte;
    logic [7:0] temperature_deci;
    logic [7:0] temperature_inte;
    logic sel_data;
    
    assign dht_io = dht_io_en ? dht_io_drv : 1'bz;


endinterface  //APB_Slave_Intferface_humi

class generator_humi;
    mailbox #(transaction_humi) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction_humi) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction_humi dht_tr;
        repeat (repeat_counter) begin
            dht_tr = new();
            if (!dht_tr.randomize()) $error("Randomization fail!");
            dht_tr.display("GEN");
            Gen2Drv_mbox.put(dht_tr);
            @(gen_next_event);
        end
    endtask  //
endclass  //generator_humi

class driver_humi;
    virtual APB_Slave_Intferface_humi dht_intf;
    mailbox #(transaction_humi) Gen2Drv_mbox;
    transaction_humi dht_tr;
    event mon_next_event;
    logic [39:0] dht_data;
        
    function new(virtual APB_Slave_Intferface_humi dht_intf,
                 mailbox#(transaction_humi) Gen2Drv_mbox,
                event mon_next_event);
        this.dht_intf = dht_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.mon_next_event = mon_next_event;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(dht_tr);
            dht_tr.display("DRV");
            @(posedge dht_intf.PCLK);
            dht_intf.PADDR   <= 4'h4;
            dht_intf.PWDATA  <= {31'b0, dht_tr.sel_data};
            dht_intf.PWRITE  <= 1'b1;
            dht_intf.PENABLE <= 1'b1;
            dht_intf.PSEL    <= 1'b1;        
            dht_intf.dht_io_en  <= 0; 
            dht_intf.dht_io_drv <= 0; 
            dht_intf.humidity_inte <= dht_tr.humidity_inte;
            dht_intf.humidity_deci <= dht_tr.humidity_deci;
            dht_intf.temperature_inte <= dht_tr.temperature_inte;
            dht_intf.temperature_deci <= dht_tr.temperature_deci;
            dht_intf.sel_data <= dht_tr.sel_data;
            @(posedge dht_intf.PCLK);
            repeat(150) @(posedge dht_intf.PCLK);
            repeat(100*18000) @(posedge dht_intf.PCLK);
            repeat(100*30) @(posedge dht_intf.PCLK);
            
            dht_intf.dht_io_en  <= 1;
            dht_intf.dht_io_drv <= 0;
            repeat(8000) @(posedge dht_intf.PCLK);

            dht_intf.dht_io_drv <= 1;
            repeat(8000) @(posedge dht_intf.PCLK);

            dht_data = {
                dht_tr.humidity_inte,
                dht_tr.humidity_deci,
                dht_tr.temperature_inte,
                dht_tr.temperature_deci,
                (dht_tr.humidity_deci + dht_tr.humidity_inte + dht_tr.temperature_deci + dht_tr.temperature_inte)
            };

            for (int i = 39; i >= 0; i--) begin
                dht_intf.dht_io_drv <= 0;
                repeat (15000) @(posedge dht_intf.PCLK);
                
                if (dht_data[i]) begin
                    dht_intf.dht_io_drv <= 1;
                    repeat (7000) @(posedge dht_intf.PCLK);
                end else begin
                    dht_intf.dht_io_drv <= 1;
                    repeat (2700) @(posedge dht_intf.PCLK);
                end
            end
            
            dht_intf.dht_io_drv <= 0;
            repeat(100) @(posedge dht_intf.PCLK);
            dht_intf.dht_io_en  <= 0;
            repeat (15000) @(posedge dht_intf.PCLK);


            dht_intf.PADDR   <= 4'h0;
            dht_intf.PWRITE  <= 1'b0;
            dht_intf.PENABLE <= 1'b1;
            dht_intf.PSEL    <= 1'b1;
            wait (dht_intf.PREADY == 1'b1);
            @(posedge dht_intf.PCLK);
            ->mon_next_event;
        end
    endtask  //

endclass  //driver_humi

class monitor_humi;
    mailbox #(transaction_humi) Mon2Scb_mbox;
    virtual APB_Slave_Intferface_humi dht_intf;
    transaction_humi dht_tr;
    event mon_next_event;

    function new(virtual APB_Slave_Intferface_humi dht_intf,
                 mailbox#(transaction_humi) Mon2Scb_mbox,
                event mon_next_event);
        this.dht_intf = dht_intf;
        this.Mon2Scb_mbox = Mon2Scb_mbox;
        this.mon_next_event = mon_next_event;
    endfunction  //new()

    task run();
        forever begin
            dht_tr = new();
            @(mon_next_event);
            #1;
            dht_tr.PADDR   = dht_intf.PADDR;
            dht_tr.PWDATA  = dht_intf.PWDATA;
            dht_tr.PWRITE  = dht_intf.PWRITE;
            dht_tr.PENABLE = dht_intf.PENABLE;
            dht_tr.PSEL    = dht_intf.PSEL;
            dht_tr.PRDATA  = dht_intf.PRDATA;  // dut out data
            dht_tr.PREADY  = dht_intf.PREADY;  // dut out data
            dht_tr.humidity_deci    = dht_intf.humidity_deci;
            dht_tr.humidity_inte    = dht_intf.humidity_inte;
            dht_tr.temperature_deci    = dht_intf.temperature_deci;
            dht_tr.temperature_inte    = dht_intf.temperature_inte;
            dht_tr.sel_data    = dht_intf.sel_data;
            dht_tr.display("Mon");
            Mon2Scb_mbox.put(dht_tr);
            repeat (5) @(posedge dht_intf.PCLK);
        end
    endtask  //run

endclass  //monitor_humi

class scoreboard_humi;
    mailbox #(transaction_humi) Mon2Scb_mbox;
    transaction_humi dht_tr;
    event gen_next_event;
    logic [15:0] expected_humidity;
    logic [15:0] expected_temperature;
    logic [7:0] expected_check_sum;
    int read_cnt, h_pass_cnt, h_fail_cnt, total_cnt;
    int t_pass_cnt, t_fail_cnt, c_pass_cnt, c_fail_cnt;

    function new(mailbox#(transaction_humi) Mon2Scb_mbox, event gen_next_event);
        this.Mon2Scb_mbox   = Mon2Scb_mbox;
        this.gen_next_event = gen_next_event;
        // RefRData = 32'b0;
    endfunction  //new()

    task run();
        forever begin
            Mon2Scb_mbox.get(dht_tr);
            dht_tr.display("SCB");
            if (!dht_tr.PWRITE) begin  // read 
                expected_humidity    = {dht_tr.humidity_deci, dht_tr.humidity_inte};       
                expected_temperature = {dht_tr.temperature_deci, dht_tr.temperature_inte};
                if (dht_tr.sel_data == 1) begin
                    if (dht_tr.PRDATA[15:0] !== expected_humidity) begin
                        $display("[SCOREBOARD] Humidity mismatch! Expected: %h, Got: %h", expected_humidity, dht_tr.PRDATA[15:0]);
                        h_fail_cnt++;
                    end else begin
                        $display("[SCOREBOARD] Humidity matched: %h", dht_tr.PRDATA[15:0]);
                        h_pass_cnt++;
                    end
                end else begin
                    if (dht_tr.PRDATA[15:0] !== expected_temperature) begin
                        $display("[SCOREBOARD] Temperature mismatch! Expected: %h, Got: %h", expected_temperature, dht_tr.PRDATA[15:0]);
                        t_fail_cnt++;
                    end else begin
                        $display("[SCOREBOARD] Temperature matched: %h", dht_tr.PRDATA[15:0]);
                        t_pass_cnt++;
                    end
                end

                // if (monitored_data !== expected_check_sum) begin
                //     $error("[SCOREBOARD] Temperature mismatch! Expected: %h, Got: %h", expected_temperature, monitored_data);
                //     t_fail_cnt++;
                // end else begin
                //     $display("[SCOREBOARD] Temperature matched: %h", monitored_data);
                //     t_pass_cnt++;
                // end
                read_cnt = read_cnt + 1;
                ->gen_next_event;
            end
            
            total_cnt = total_cnt + 1;
        end

    endtask  //run

    task report();
        $display("===========================================");
        $display("==             Final Report              ==");
        $display("===========================================");
        $display("       Read Test  : %0d", read_cnt);
        $display("(^-^)b PASS Test  : HUMI = %0d / TEMP = %0d", h_pass_cnt, t_pass_cnt);
        $display("(;-;)p FAIL Test  : HUMI = %0d / TEMP = %0d", h_fail_cnt, t_fail_cnt);
        $display("       Total Test : %0d ", total_cnt);
        $display("===========================================");
        $display("===========================================");
    endtask  //report

endclass  //scoreboard_humi

class envirnment_humi;
    mailbox #(transaction_humi) Gen2Drv_mbox;
    mailbox #(transaction_humi) Mon2Scb_mbox;

    generator_humi dht_gen;
    driver_humi dht_drv;
    monitor_humi dht_mon;
    scoreboard_humi dht_scb;

    event gen_next_event;
    event mon_next_event;

    function new(virtual APB_Slave_Intferface_humi dht_intf);
        Gen2Drv_mbox = new();
        Mon2Scb_mbox = new();
        this.dht_gen = new(Gen2Drv_mbox, gen_next_event);
        this.dht_drv = new(dht_intf, Gen2Drv_mbox, mon_next_event);
        this.dht_mon = new(dht_intf, Mon2Scb_mbox, mon_next_event);
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
endclass  //envirnment_humi

module tb_Humid_sys(

    );

    envirnment_humi dht_env;
    APB_Slave_Intferface_humi dht_intf ();

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
        dht_env.run(30);
        #30;
        $finish;
    end
endmodule
