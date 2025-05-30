`timescale 1ns / 1ps


module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    // ov7670 signals
    output logic       ov7670_x_clk,
    input  logic       ov7670_pixel_clk,
    input  logic       ov7670_href,
    input  logic       ov7670_vsync,
    input  logic [7:0] ov7670_data,
    // export signals
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    logic        display_en;
    logic [9:0]  x_coor;
    logic [8:0]  y_coor;
    logic        we;
    logic [16:0] wAddr, rAddr;
    logic [15:0] wData, rData;
    logic w_rclk, rclk;
    logic oe;

    vga_Controller U_VGA_CONTROLLER (
        .clk       (clk),
        .reset     (reset),
        .Hsync     (Hsync),
        .Vsync     (Vsync),
        .display_en(display_en),
        .x_coor    (x_coor),
        .y_coor    (y_coor),
        .pixel_clk (ov7670_x_clk),
        .rclk      (w_rclk)
    );

    // Mem_Controller U_OV7670_MEM(
    //     .PCLK(ov7670_pixel_clk),
    //     .reset(reset),
    //     .HREF(ov7670_href),
    //     .VSYNC(ov7670_vsync),
    //     .i_data(ov7670_data),
    //     .wen(we),
    //     .waddr(wAddr),
    //     .wdata(wData)
    // );


    OV7670_MemController U_OV7670_MEM (
        .pclk       (ov7670_pixel_clk),
        .reset      (reset),
        .href       (ov7670_href),
        .vsync      (ov7670_vsync),
        .ov7670_data(ov7670_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData)
    );

    frame_buffer U_FRAME_BUFF (
        .wclk (ov7670_pixel_clk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    QVGA_MemController U_QVGA_MEM (
        .clk       (w_rclk),
        .x_coor    (x_coor),
        .y_coor    (y_coor),
        .display_en(display_en),
        .rclk      (rclk),
        .de        (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .vgaRed    (vgaRed),
        .vgaGreen  (vgaGreen),
        .vgaBlue   (vgaBlue)
    );

endmodule
