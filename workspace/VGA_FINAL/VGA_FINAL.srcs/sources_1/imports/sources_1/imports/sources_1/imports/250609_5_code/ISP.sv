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
// 지금 파이프라인이 좀 밀리는 현상이 발생하고 있음
// 아무래도 x, y 좌표를 좀 전달해주는 로직을 추가해야할듯 음
// 일단은 더하는 기존 데이터를 좀 샤프닝 필터랑 좌표를 맞춰볼건데
// 음 옆으로 밀리니까 화면 두 개 띄울 때 별로 좋지 않을지도
//////////////////////////////////////////////////////////////////////////////////


module ISP(
    input logic i_clk,
    input wire reset,
    input logic [5:0] rgb_sw,
    input logic i_DE1_sw,
    input logic i_DE3_sw,
    input logic [1:0] btn,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic [1:0] g_btn,
    input logic oe,
    input logic [11:0] BASE_RGB444_data,
    output logic [11:0] O_RGB444_data,
    input logic [11:0] BASE_RGB444_data2,
    output logic [11:0] O_RGB444_data2
);

    logic [5:0] DE1_sw, DE3_sw;
    logic [1:0] DE1_btn, DE3_btn;
    bit clk;
    logic [9:0] w_x_coor1, w_x_coor2, w_x_coor3, w_x_coor4, w_x_coor5, w_x_coor6, w_x_coor7;
    logic [8:0] w_y_coor1, w_y_coor2, w_y_coor3, w_y_coor4, w_y_coor5, w_y_coor6, w_y_coor7;
    logic [9:0] w_x_coor12, w_x_coor22;
    logic [8:0] w_y_coor12, w_y_coor22;

    always_comb begin
        case ({i_DE1_sw, i_DE3_sw})
            2'b00: begin
                DE1_sw = 6'bz;
                DE1_btn = 2'bz;
                DE3_sw = 6'bz;
                DE3_btn = 2'bz;
            end
            2'b01: begin
                DE1_sw = 6'bz;
                DE1_btn = 2'bz;
                DE3_sw = rgb_sw;
                DE3_btn = btn;
            end
            2'b10: begin
                DE1_sw = rgb_sw;
                DE1_btn = btn;
                DE3_sw = 6'bz;
                DE3_btn = 2'bz;
            end
            2'b11: begin
                DE1_sw = rgb_sw;
                DE1_btn = btn;
                DE3_sw = rgb_sw;
                DE3_btn = btn;
            end
        endcase
    end

    clock_div #(
        .FCOUNT(4)
    ) U_PIXEL_GENERATOR_filter (
        .*,
        .clk(i_clk),
        .o_clk(clk)
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
    logic [11:0] L_SHARP_RGB444_data;
    logic [11:0] L_SHARPNESS_RGB444_data;
    logic [11:0] S_SHARP_RGB444_data;
    logic [11:0] S_SHARPNESS_RGB444_data;
    logic [11:0] C_SHARP_RGB444_data;
    logic [11:0] C_SHARPNESS_RGB444_data;
    logic [11:0] SOBEL_RGB444_data;
    logic [11:0] SCHARR_RGB444_data;
    logic [11:0] MOPOL_RGB444_data;
    logic [11:0] EDGE_MOPOL_RGB444_data;
    logic [11:0] EDGE_RGB444_data;

    
    logic [11:0] GRAY_RGB444_data2;
    logic [11:0] LAPLA_RGB444_data2;
    logic [11:0] SOBEL_RGB444_data2;
    logic [11:0] SCHARR_RGB444_data2;
    logic [11:0] MOPOL_RGB444_data2;
    logic [11:0] SECOND_RGB444_data2;
    logic [11:0] EDGE_MOPOL_RGB444_data2;
    logic [11:0] EDGE_RGB444_data2;

    bit le;
    bit me;
    bit laen;
    bit ame;
    bit ge;
    
    // ---------------- first filter -----------------------------
    // ---------------RGB, GRAY filter ---------------------------

    GrayScale_Filter U_GS_F (
        .data(BASE_RGB444_data),
        .RGBdata(GRAY_RGB444_data)
    );
    GrayScale_Filter U_GS_F2 (
        .data(BASE_RGB444_data2),
        .RGBdata(GRAY_RGB444_data2)
    );

    RGBScale_Filter U_RGB_F (
        .i_data (BASE_RGB444_data),
        .ro_data(RED_RGB444_data),
        .go_data(GREEN_RGB444_data),
        .bo_data(BLUE_RGB444_data)
    );

/*
    Filter_mux U_F_mux (
        .clk(clk),
        .reset(reset),
        .sel(DE1_sw[1]),
        .btn(DE1_btn),
        .x0 (BASE_RGB444_data),
        .x1 (GRAY_RGB444_data),
        .x2 (RED_RGB444_data),
        .x3 (GREEN_RGB444_data),
        .x4 (BLUE_RGB444_data),
        .y  (FIRST_RGB444_data)
    );
*/

    // ---------------- second filter -----------------------------
    // ---------------Gaussian, Croma_key filter ------------------


    Gaussian_Blur U_GAUSS_GRAY (
        .clk(clk),
        .reset(reset),
        .x_coor(x_coor),
        .y_coor(y_coor),
        .i_data(BASE_RGB444_data[3:0]),
        .de(oe),
        .up_btn(g_btn[0]),
        .down_btn(g_btn[1]),
        .le(le),
        .o_data(GAUSS_GRAY444_data),
        .w_x_coor(w_x_coor1),
        .w_y_coor(w_y_coor1)
    );
    
    
    Croma_Key_Filter U_CROMA (
        .data(BASE_RGB444_data),
        .Croma_Key_data(CROMA_RGB444_data)
    );

    Mopology_Filter U_MOPOL_BERFORE_EDGE (
        .clk(clk),
        .reset(reset), 
        .x_coor(w_x_coor1),
        .y_coor(w_y_coor1),
        .w_x_coor(w_x_coor2),
        .w_y_coor(w_y_coor2),
        .i_data(GAUSS_GRAY444_data),
        .DE(le),             
        .moe(me),            
        .o_data(MOPOL_RGB444_data)  
    );


    Filter_mux U_S_mux (
        .clk(clk),
        .reset(reset),
        .sel(DE1_sw[1]),
        .btn(DE1_btn),
        .x0 (BASE_RGB444_data),
        .x1 (CROMA_RGB444_data),
        .x2 (GAUSS_GRAY444_data),
        .x3 (MOPOL_RGB444_data),
        .x4 (BASE_RGB444_data),
        .y  (SECOND_RGB444_data)
    );

    always_comb begin
        case (SECOND_RGB444_data)
            GAUSS_GRAY444_data: begin
                w_x_coor3 = w_x_coor1;
                w_y_coor3 = w_y_coor1;
            end
            MOPOL_RGB444_data: begin
                w_x_coor3 = w_x_coor2;
                w_y_coor3 = w_y_coor2;                
            end
            default: begin
                w_x_coor3 = x_coor;
                w_y_coor3 = y_coor;
            end
        endcase
    end

    // ---------------- third filter -----------------------------
    // -------------Sharpness Laplasian, Sobel, Scharr filter --------------

    Laplasian_Filter U_LAPLA_SHARP_EDGE(
        .clk(clk),
        .reset(reset),
        .x_coor(w_x_coor3),
        .y_coor(w_y_coor3),
        .w_x_coor(w_x_coor4),
        .w_y_coor(w_y_coor4),
        .de(me),
        .laen(laen),
        .g_data(SECOND_RGB444_data),
        .l_data(),
        .ls_data(L_SHARP_RGB444_data)
    );

    Sobel_Filter U_SOBEL_SHARP_EDGE(
        .clk(clk),
        .reset(reset),
        .x_coor(w_x_coor3),
        .y_coor(w_y_coor3),
        .gray_in(SECOND_RGB444_data),
        .de(me),
        .sobel_out(),
        .scharr_out(),
        .s_sobel(S_SHARP_RGB444_data),
        .s_scharr(C_SHARP_RGB444_data)
    );

    Sharpness_Filter U_LAPLA_SHARP(
        .BASE_RGB444_data(GRAY_RGB444_data),
        .FILTERED_RGB444_data(L_SHARP_RGB444_data),
        .SHARPNESS_RGB444_data(L_SHARPNESS_RGB444_data)
    );
    Sharpness_Filter U_SOBEL_SHARP(
        .BASE_RGB444_data(GRAY_RGB444_data),
        .FILTERED_RGB444_data(S_SHARP_RGB444_data),
        .SHARPNESS_RGB444_data(S_SHARPNESS_RGB444_data)
    );
    Sharpness_Filter U_SCHARR_SHARP(
        .BASE_RGB444_data(GRAY_RGB444_data),
        .FILTERED_RGB444_data(C_SHARP_RGB444_data),
        .SHARPNESS_RGB444_data(C_SHARPNESS_RGB444_data)
    );

    Filter_mux U_sharpness_mux (
        .clk(clk),
        .reset(reset),
        .sel(DE1_sw[2]),
        .btn(DE1_btn),
        .x0 (SECOND_RGB444_data),
        .x1 (SECOND_RGB444_data),
        .x2 (L_SHARPNESS_RGB444_data),
        .x3 (S_SHARPNESS_RGB444_data),
        .x4 (C_SHARPNESS_RGB444_data),
        .y  (THIRD_RGB444_data)
    );

    always_comb begin
        case (THIRD_RGB444_data)
            SECOND_RGB444_data: begin
                w_x_coor5 = w_x_coor3;
                w_y_coor5 = w_y_coor3;
            end
            default: begin
                w_x_coor5 = w_x_coor4;
                w_y_coor5 = w_y_coor4;
            end
        endcase
    end

    Laplasian_Filter U_LAPLA(
        .clk(clk),
        .reset(reset),
        .x_coor(w_x_coor5),
        .y_coor(w_y_coor5),
        .w_x_coor(w_x_coor6),
        .w_y_coor(w_y_coor6),
        .de(me),
        .laen(laen),
        .g_data(THIRD_RGB444_data),
        .l_data(LAPLA_RGB444_data),
        .ls_data()
    );

    Sobel_Filter U_SOBEL(
        .clk(clk),
        .reset(reset),
        .x_coor(w_x_coor5),
        .y_coor(w_y_coor5),
        .gray_in(THIRD_RGB444_data),
        .de(me),
        .sobel_out(SOBEL_RGB444_data),
        .scharr_out(SCHARR_RGB444_data),
        .s_sobel(),
        .s_scharr()
    );


    Laplasian_Filter U_LAPLA2(
        .clk(clk),
        .reset(reset),
        .x_coor(x_coor),
        .y_coor(y_coor),
        .w_x_coor(w_x_coor12),
        .w_y_coor(w_y_coor12),
        .de(me),
        .laen(laen),
        .g_data(GRAY_RGB444_data2),
        .l_data(LAPLA_RGB444_data2),
        .ls_data()
    );

    Sobel_Filter U_SOBEL2(
        .clk(clk),
        .reset(reset),
        .x_coor(x_coor),
        .y_coor(y_coor),
        .gray_in(GRAY_RGB444_data2),
        .de(me),
        .sobel_out(SOBEL_RGB444_data2),
        .scharr_out(SCHARR_RGB444_data2),
        .s_sobel(),
        .s_scharr()
    );

    Filter_mux U_edge_mux (
        .clk(clk),
        .reset(reset),
        .sel(DE1_sw[3]),
        .btn(DE1_btn),
        .x0 (THIRD_RGB444_data),
        .x1 (THIRD_RGB444_data),
        .x2 (LAPLA_RGB444_data),
        .x3 (SOBEL_RGB444_data),
        .x4 (SCHARR_RGB444_data),
        .y  (EDGE_RGB444_data)
    );

    Filter_mux U_edge_mux2 (
        .clk(clk),
        .reset(reset),
        .sel(DE3_sw[3]),
        .btn(DE3_btn),
        .x0 (BASE_RGB444_data2),
        .x1 (GRAY_RGB444_data2),
        .x2 (LAPLA_RGB444_data2),
        .x3 (SOBEL_RGB444_data2),
        .x4 (SCHARR_RGB444_data2),
        .y  (EDGE_RGB444_data2)
    );

    always_comb begin
        case (EDGE_RGB444_data)
            THIRD_RGB444_data: begin
                w_x_coor7 = w_x_coor5;
                w_y_coor7 = w_y_coor5;
            end
            default: begin
                w_x_coor7 = w_x_coor6;
                w_y_coor7 = w_y_coor6;
            end
        endcase
        case (EDGE_RGB444_data2)
            BASE_RGB444_data2, GRAY_RGB444_data2: begin
                w_x_coor22 = x_coor;
                w_y_coor22 = y_coor;
            end
            default: begin
                w_x_coor22 = w_x_coor12;
                w_y_coor22 = w_y_coor12;
            end
        endcase
    end

    Mopology_Filter U_MOPOL_AFTER_EDGE (
        .clk(clk),
        .reset(reset), 
        .x_coor(w_x_coor7),
        .y_coor(w_y_coor7),
        .w_x_coor(),
        .w_y_coor(),
        .i_data(EDGE_RGB444_data),
        .DE(le),             
        .moe(),             
        .o_data(EDGE_MOPOL_RGB444_data)  
    );
    Mopology_Filter U_MOPOL_AFTER_EDGE2 (
        .clk(clk),
        .reset(reset), 
        .x_coor(w_x_coor22),
        .y_coor(w_y_coor22),
        .w_x_coor(),
        .w_y_coor(),
        .i_data(EDGE_RGB444_data2),
        .DE(le),             
        .moe(),             
        .o_data(EDGE_MOPOL_RGB444_data2)  
    );

    Filter_mux U_edge_mopol_mux (
        .clk(clk),
        .reset(reset),
        .sel(DE1_sw[4]),
        .btn(DE1_btn),
        .x0 (EDGE_RGB444_data),
        .x1 (EDGE_MOPOL_RGB444_data),
        .x2 (EDGE_RGB444_data),
        .x3 (EDGE_MOPOL_RGB444_data),
        .x4 (EDGE_RGB444_data),
        .y  (O_RGB444_data)
    );

    Filter_mux U_edge_mopol_mux2 (
        .clk(clk),
        .reset(reset),
        .sel(DE3_sw[4]),
        .btn(DE3_btn),
        .x0 (EDGE_RGB444_data2),
        .x1 (EDGE_MOPOL_RGB444_data2),
        .x2 (EDGE_RGB444_data2),
        .x3 (EDGE_MOPOL_RGB444_data2),
        .x4 (EDGE_RGB444_data2),
        .y  (O_RGB444_data2)
    );

endmodule
