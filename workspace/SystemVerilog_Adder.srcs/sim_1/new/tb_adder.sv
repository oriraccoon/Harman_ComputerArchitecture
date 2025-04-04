`timescale 1ns / 1ps

interface adder_intf;
    logic [7:0] a; // wire + reg => 사용하는 용도에 맞게 알아서 조정됨
    logic [7:0] b;
    logic [7:0] sum;
    logic carry;
endinterface //adder_intf

class transaction;
    rand bit [7:0] a; // Z, X 없이 0과 1뿐인 자료형
    rand bit [7:0] b;
endclass //transaction

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbx;
    
    function new(mailbox#(transaction) gen2drv_mbx);
        this.gen2drv_mbx = gen2drv_mbx;
               
    endfunction //new()

    task run(int run_count);
        repeat (run_count) begin
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
        adder_interface.a = 0;
        adder_interface.b = 0;
    endtask //reset

    task run ();
        forever begin
            gen2drv_mbx.get(tr);
            adder_interface.a = tr.a;
            adder_interface.b = tr.b;
            #10;
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
        fork
            gen.run(1000);
            drv.run();
        join_any
        #10 $finish;
    endtask //run
endclass //env


    
module tb_adder ();
    Env env;
    adder_intf adder_interface();

    Adder DUT(
        .a(adder_interface.a),
        .b(adder_interface.b),
        .sum(adder_interface.sum),
        .carry(adder_interface.carry)
    );

    initial begin
        env = new(adder_interface);
        env.run();
    end

endmodule
