`timescale 1ns / 1ps

module tb_vga_switch_rgb_display ();

    logic       clk;
    logic       reset;
    logic [3:0] r_sw;
    logic [3:0] g_sw;
    logic [3:0] b_sw;
    logic       Hsync;
    logic       Vsync;
    logic [3:0] vgaRed;
    logic [3:0] vgaGreen;
    logic [3:0] vgaBlue;

    VGA_Controller dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1;
        #10 reset = 0;
        #100 r_sw = 4'd0; g_sw = 4'd15; b_sw = 4'd0;

        repeat(2) begin
            wait(Vsync == 0);
            wait(Vsync == 1);
        end


        #200$finish;
    end

endmodule

