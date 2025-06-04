`timescale 1ns / 1ps


module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    input  logic [4:0] rgb_sw,
    input  logic [1:0] btn,
    input logic bg_sw,
    input  logic       up_btn,
    input  logic       down_btn,
    // ov7670 signals
    output logic       ov7670_x_clk,
    input  logic       ov7670_pixel_clk,
    input  logic       ov7670_href,
    input  logic       ov7670_vsync,
    input  logic [7:0] ov7670_data,
    output logic       SCL,
    output logic       SDA,
    // export signals
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    logic       display_en;
    logic [9:0] x_coor;
    logic [8:0] y_coor;
    logic       we;
    logic [16:0] wAddr, rAddr;
    logic [11:0] wData, rData;
    logic w_rclk;
    logic rclk;
    logic oe;
    logic VGA_SIZE;


    logic [11:0] BASE_RGB444_data;
    logic [11:0] O_RGB444_data;

    always_comb begin
        {vgaRed, vgaGreen, vgaBlue} = O_RGB444_data;
        VGA_SIZE = rgb_sw[0];
    end


    /*
    SCCB_intf U_SCCB(
        .clk(clk),
        .reset(reset),
        .SCL(SCL),
        .SDA(SDA)
    );*/



    vga_Controller U_VGA_CONTROLLER (
        .clk       (clk),
        .reset     (reset),
        .Hsync     (Hsync),
        .Vsync     (Vsync),
        .display_en(display_en),
        .x_coor    (x_coor),
        .y_coor    (y_coor),
        .pixel_clk (ov7670_x_clk)
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

    // OV7670_MemController U_OV7670_MEM(
    //     .pclk(ov7670_pixel_clk),
    //     .reset(reset),
    //     .href(ov7670_href),
    //     .vsync(ov7670_vsync),
    //     .ov7670_data(ov7670_data),
    //     .we(we),
    //     .wAddr(wAddr),
    //     .wData(wData)
    // );

    ov7670_controller U_OV7670_MEM (
        .pclk(ov7670_pixel_clk),
        .reset(reset),
        .href(ov7670_href),
        .vsync(ov7670_vsync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    frame_buffer U_FRAME_BUFF (
        .wclk (ov7670_pixel_clk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(clk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    QVGA_MemController U_QVGA_MEM (
        .clk       (clk),
        .x_coor    (x_coor),
        .y_coor    (y_coor),
        .VGA_SIZE  (VGA_SIZE),
        .display_en(display_en),
        .de        (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .vgaRed    (BASE_RGB444_data[11:8]),
        .vgaGreen  (BASE_RGB444_data[7:4]),
        .vgaBlue   (BASE_RGB444_data[3:0])
    );


    ISP U_ISP (
        .*,
        .i_clk(clk)
    );


endmodule
