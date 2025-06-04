`timescale 1ns / 1ps


module OV7670_VGA_Display (
    // global signals
    input  logic       clk,
    input  logic       reset,
    input  logic [4:0] rgb_sw,
    input logic [1:0] btn,
    input logic up_btn,
    input logic down_btn,
    // ov7670 signals
    output logic       ov7670_x_clk,
    input  logic       ov7670_pixel_clk,
    input  logic       ov7670_href,
    input  logic       ov7670_vsync,
    input  logic [7:0] ov7670_data,
    output logic SCL,
    output logic SDA,
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
    logic [11:0] wData, rData;
    logic w_rclk;
    logic rclk;
    logic oe;
    logic le;
    logic me;
    logic laen;
    logic ame;
    logic VGA_SIZE;

    logic [11:0] BRIGHT_RGB444_data;
    logic [11:0] GRAY_RGB444_data;
    logic [3:0] GRAY_RGB444_data_4bit;
    logic [11:0] BASE_RGB444_data;
    logic [11:0] O_RGB444_data;
    logic [11:0] RED_RGB444_data;
    logic [11:0] GREEN_RGB444_data;
    logic [11:0] BLUE_RGB444_data;
    logic [11:0] FIRST_RGB444_data;
    logic [11:0] SECOND_RGB444_data;
    logic [11:0] THIRD_RGB444_data;
    logic [11:0] CROMA_RGB444_data;
    logic [11:0] GAUSS_GRAY444_data;
    logic [11:0] LAPLA_RGB444_data;
    logic [11:0] SOBEL_RGB444_data;
    logic [11:0] SCHARR_RGB444_data;
    logic [11:0] MOPOL_RGB444_data;
    logic [11:0] EDGE_MOPOL_RGB444_data;
    logic [11:0] GAMMA_RGB444_data;


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
    
    ov7670_controller U_OV7670_MEM(
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




    // ---------------- first filter -----------------------------
    // ---------------RGB, GRAY filter ---------------------------

    GrayScale_Filter U_GS_F (
        .data(BASE_RGB444_data),
        .RGBdata(GRAY_RGB444_data)
    );
    GrayScale_Filter_4bit U_GS_F_4bit (
        .data(BASE_RGB444_data),
        .RGBdata(GRAY_RGB444_data_4bit)
    );

    RGBScale_Filter U_RGB_F (
        .i_data (BASE_RGB444_data),
        .ro_data(RED_RGB444_data),
        .go_data(GREEN_RGB444_data),
        .bo_data(BLUE_RGB444_data)
    );

    Filter_mux U_F_mux (
        .clk(clk),
        .reset(reset),
        .sel(rgb_sw[1]),
        .btn(btn),
        .x0 (BASE_RGB444_data),
        .x1 (GRAY_RGB444_data),
        .x2 (RED_RGB444_data),
        .x3 (GREEN_RGB444_data),
        .x4 (BLUE_RGB444_data),
        .y  (FIRST_RGB444_data)
    );


    // ---------------- second filter -----------------------------
    // ---------------Gaussian, Croma_key filter ------------------

    Gaussian_Blur U_GAUSS_GRAY (
        .*,
        .i_data(GRAY_RGB444_data_4bit),
        .de(oe),
        .le(le),
        .o_data(GAUSS_GRAY444_data)
    );
    
    Croma_Key_Filter U_CROMA (
        .data(FIRST_RGB444_data),
        .Croma_Key_data(CROMA_RGB444_data)
    );

    Mopology_Filter U_MOPOL_BERFORE_EDGE (
        .*,
        .i_data(GAUSS_GRAY444_data),
        .de(le),             
        .oe(me),            
        .o_data(MOPOL_RGB444_data)  
    );

    Filter_mux U_S_mux (
        .clk(clk),
        .reset(reset),
        .sel(rgb_sw[2]),
        .btn(btn),
        .x0 (FIRST_RGB444_data),
        .x1 (CROMA_RGB444_data),
        .x2 (GAUSS_GRAY444_data),
        .x3 (MOPOL_RGB444_data),
        .x4 (FIRST_RGB444_data),
        .y  (SECOND_RGB444_data)
    );

    // ---------------- third filter -----------------------------
    // -------------Laplasian, Sobel, Scharr filter --------------

    Laplasian_Filter U_LAPLA(
        .*,
        .de(me),
        .laen(laen),
        .g_data(SECOND_RGB444_data),
        .l_data(LAPLA_RGB444_data)
    );

    Sobel_Filter U_SOBEL(
        .*,
        .gray_in(SECOND_RGB444_data),
        .de(me),
        .sobel_out(SOBEL_RGB444_data),
        .scharr_out(SCHARR_RGB444_data)
    );


    Filter_mux U_edge_mux (
        .clk(clk),
        .reset(reset),
        .sel(rgb_sw[3]),
        .btn(btn),
        .x0 (SECOND_RGB444_data),
        .x1 (LAPLA_RGB444_data),
        .x2 (SOBEL_RGB444_data),
        .x3 (SCHARR_RGB444_data),
        .x4 ( SECOND_RGB444_data ),
        .y  (THIRD_RGB444_data)
    );


    Mopology_Filter U_MOPOL_AFTER_EDGE (
        .*,
        .i_data(THIRD_RGB444_data),
        .de(laen),             
        .oe(ame),            
        .o_data(EDGE_MOPOL_RGB444_data)  
    );
/*
    Bright_Controller U_BRIGHT (
        .*,
        .en(laen),
        .i_data(THIRD_RGB444_data),
        .o_data(BRIGHT_RGB444_data) 
    );

    Gamma_Filter U_GAMMA (
        .en(laen),
        .rgb_in(THIRD_RGB444_data),
        .rgb_out(GAMMA_RGB444_data)
    );*/

    Filter_mux U_after_edge_mux (
        .clk(clk),
        .reset(reset),
        .sel(rgb_sw[4]),
        .btn(btn),
        .x0 (THIRD_RGB444_data),
        .x1 (EDGE_MOPOL_RGB444_data),
        .x2 (EDGE_MOPOL_RGB444_data),
        .x3 (EDGE_MOPOL_RGB444_data),
        .x4 ( EDGE_MOPOL_RGB444_data ),
        .y  (O_RGB444_data)
    );


endmodule
