`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/30 12:39:07
// Design Name: 
// Module Name: tb_vga_ov
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_vga_ov ();

    // OV7670 Input
    logic        PCLK;
    logic        reset;
    logic        HREF;
    logic        VSYNC;
    logic [ 7:0] i_data;
    logic [16:0] raddr;
    logic [15:0] rdata;

    VGA_OV7670 dut (.*);

    always #5 PCLK = ~PCLK;

    initial begin
        PCLK = 0;
        reset = 1;
        HREF = 0;
        VSYNC = 0;
        i_data = 8'b1010_1010;
        raddr = 0;
        #10 reset = 0;

        #10 HREF = 1;
        repeat(320) begin
            @(posedge dut.U_MEM_CONTROLLER.FCLK);
            i_data = i_data + 8'b0000_0101;
            @(negedge dut.U_MEM_CONTROLLER.FCLK);
            i_data = i_data + 8'b0000_0101;
        end
        @(negedge PCLK); HREF = 0;

        #200 $finish;
    end
endmodule
