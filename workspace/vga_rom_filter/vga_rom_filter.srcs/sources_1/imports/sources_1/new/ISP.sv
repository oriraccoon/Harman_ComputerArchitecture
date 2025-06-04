`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/04 15:57:22
// Design Name: 
// Module Name: ISP
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


module ISP(
    input logic clk,
    input logic reset,
    input logic [9:0]  x_coor,
    input logic [8:0]  y_coor,
    input logic [4:0] rgb_sw,
    input logic [1:0] btn,
    input logic up_btn,
    input logic down_btn,
    input logic oe,
    input logic [11:0] BASE_RGB444_data,
    output logic [11:0] O_RGB444_data
    );

    logic [11:0] BRIGHT_RGB444_data;
    logic [11:0] GRAY_RGB444_data;
    logic [3:0] GRAY_RGB444_data_4bit;
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


    logic le;
    logic me;
    logic laen;
    logic ame;



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
