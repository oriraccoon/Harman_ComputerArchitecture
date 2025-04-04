`timescale 1ns / 1ps


module tb_uart ();

    reg clk;
    reg rst;
    reg rx;
    wire tx;

    top_counter_up_down dut(
        .clk(clk),
        .reset(rst),
        .rx(rx),
        .tx(tx)
    );
    always #1 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;

        #20 
        rst = 0;
        #2
        
        rx = 0; #869; send_bit("r"); rx = 1; #2604;
        #2
        rx = 0; #869; send_bit("c"); rx = 1; #2604;
                #2
        rx = 0; #869; send_bit("m"); rx = 1; #2604;
                #2
        #10000;
        $finish;
    end

    task send_bit(input [7:0] data);
        integer i;
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #1738;
        end
    endtask


endmodule
