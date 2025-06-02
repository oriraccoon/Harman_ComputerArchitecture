`timescale 1ns / 1ps


module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] rgb_sw,
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

    logic [11:0] G_RGB444_data;
    logic [11:0] C_RGB444_data;
    logic [11:0] O_RGB444_data;
    logic [11:0] RED_RGB444_data;
    logic [11:0] GREEN_RGB444_data;
    logic [11:0] BLUE_RGB444_data;


    always_comb begin
        {vgaRed, vgaGreen, vgaBlue} = O_RGB444_data;
    end


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

    Mem_Controller U_OV7670_MEM(
        .PCLK(ov7670_pixel_clk),
        .reset(reset),
        .HREF(ov7670_href),
        .VSYNC(ov7670_vsync),
        .i_data(ov7670_data),
        .wen(we),
        .waddr(wAddr),
        .wdata(wData)
    );


    // OV7670_MemController U_OV7670_MEM (
    //     .pclk       (ov7670_pixel_clk),
    //     .reset      (reset),
    //     .href       (ov7670_href),
    //     .vsync      (ov7670_vsync),
    //     .ov7670_data(ov7670_data),
    //     .we         (we),
    //     .wAddr      (wAddr),
    //     .wData      (wData)
    // );

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
        .VGA_SIZE  (rgb_sw[3]),
        .display_en(display_en),
        .rclk      (rclk),
        .de        (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .vgaRed    (C_RGB444_data[11:8]),
        .vgaGreen  (C_RGB444_data[7:4]),
        .vgaBlue   (C_RGB444_data[3:0])
    );


    GrayScale_Filter U_GS_F (
        .data(C_RGB444_data),
        .RGBdata(G_RGB444_data)
    );

    RGBScale_Filter U_RGB_F (
        .i_data (C_RGB444_data),
        .ro_data(RED_RGB444_data),
        .go_data(GREEN_RGB444_data),
        .bo_data(BLUE_RGB444_data)
    );

    Filter_mux U_F_mux (
        .sel(rgb_sw[2:0]),
        .x0 (C_RGB444_data),
        .x1 (G_RGB444_data),
        .x2 (RED_RGB444_data),
        .x3 (GREEN_RGB444_data),
        .x4 (BLUE_RGB444_data),
        .y  (O_RGB444_data)
    );

endmodule
