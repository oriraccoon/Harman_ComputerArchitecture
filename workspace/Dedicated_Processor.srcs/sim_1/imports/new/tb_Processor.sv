`timescale 1ns / 1ps

module tb_Processor ();

    logic clk;
    logic rst;

    Dedicate_Processor dut(
    .clk(clk),
    .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #20 rst = 0;
    end

endmodule
