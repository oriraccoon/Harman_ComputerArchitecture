`timescale 1ns / 1ps


interface adder_intf;
    logic [3:0] repeat_num;
    logic [2:0] start_num;
    logic [7:0] outvalue;
endinterface //adder_intf

class transaction;
    rand bit [3:0] repeat_num;
    rand bit [2:0] start_num;
endclass //transaction

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbx;
    
    function new(mailbox#(transaction) gen2drv_mbx);
        this.gen2drv_mbx = gen2drv_mbx;
               
    endfunction //new()

    task run(int run_time);
        repeat(run_time) begin
            tr = new();
            tr.randomize();
            gen2drv_mbx.put(tr);
            #10;
        end
    endtask //run

endclass //generator

class driver;
    transaction tr;
    virtual adder_intf adder_interface;

    mailbox #(transaction) gen2drv_mbx;

    function new(mailbox#(transaction) gen2drv_mbx, virtual adder_intf adder_interface);
        this.gen2drv_mbx = gen2drv_mbx;
        this.adder_interface = adder_interface;
    endfunction //new()

    task reset ();
        adder_interface.repeat_num = 0;
        adder_interface.start_num = 0;
    endtask //reset

    task run ();
        forever begin
            gen2drv_mbx.get(tr);
            adder_interface.repeat_num = tr.repeat_num;
            adder_interface.start_num = tr.start_num;
            #1000;
        end
    endtask //run

endclass //driver

class Env;
    generator gen;
    driver drv;
    mailbox #(transaction) gen2drv_mbx;

    function new(virtual adder_intf adder_interface);
        gen2drv_mbx = new();
        gen = new(gen2drv_mbx);
        drv = new(gen2drv_mbx, adder_interface);
    endfunction //new()

    task run ();
        drv.reset();
        fork
            gen.run(10);
            drv.run();
        join
        #10 $finish;
    endtask //run
endclass //env


module tb_Processor ();
    Env env;
    adder_intf adder_interface();
    
    bit clk;
    bit rst;
    
    Dedicate_Processor dut(
    .clk(clk),
    .rst(rst),
    .repeat_num(adder_interface.repeat_num),
    .start_num(adder_interface.start_num),
    .outvalue(adder_interface.outvalue)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        rst = 1;
        adder_interface.repeat_num = 0;
        adder_interface.start_num = 0;
        
        #10
        rst = 0;
        env = new(adder_interface);
        env.run();
        
        
    end

endmodule
