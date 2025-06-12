`timescale 1ns / 1ps

module Contrast (
    input logic clk,
    input logic reset,
    input logic up_btn,
    input logic down_btn,
    input logic [9:0] x_pixel,
    input logic [8:0] y_pixel,
    input logic [11:0] rgb,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);

    logic [7:0] gain_fixed;
    logic [2:0] contrast_level;
    logic r_down_btn, r_up_btn;
    logic [3:0] avg_data;

    btn_edge_trigger U_UP_BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (reset),
        .i_btn(up_btn),
        .o_btn(r_up_btn)
    );

    btn_edge_trigger U_DOWN_BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (reset),
        .i_btn(down_btn),
        .o_btn(r_down_btn)
    );

    brightness_controller U_avg (
        .clk_25MHz(clk),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .gray_image(rgb),
        .avg_data(avg_data)
);

    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            contrast_level <= 0;
        end else begin
            if (r_up_btn && contrast_level < 3'd7) contrast_level <= contrast_level + 1;
            else if (r_down_btn && contrast_level > 3'd0) contrast_level <= contrast_level - 1;
            else contrast_level <= contrast_level;  
        end
    end

    // contrast_level별 fixed-point 정의
    always_comb begin
        case (contrast_level)  
            3'd0: gain_fixed = 8'd1;
            3'd1: gain_fixed = 8'd2;
            3'd2: gain_fixed = 8'd3;
            3'd3: gain_fixed = 8'd4;

            3'd4: gain_fixed = 8'd5;
            3'd5: gain_fixed = 8'd6;
            3'd6: gain_fixed = 8'd7;
            3'd7: gain_fixed = 8'd8;
            default: gain_fixed = 8'd4; // 원본 유지지
        endcase
    end

    // signed로 확장
    logic signed [4:0] sR = $signed({1'b0, rgb[11:8]});
    logic signed [4:0] sG = $signed({1'b0, rgb[7:4]});
    logic signed [4:0] sB = $signed({1'b0, rgb[3:0]});
    logic signed [4:0] mid = $signed({1'b0, avg_data});

    // sub
    logic signed [5:0] cR = sR - mid;
    logic signed [5:0] cG = sG - mid;
    logic signed [5:0] cB = sB - mid;
    
    // sub*gain_fixed
    logic signed [13:0] pR = cR * $signed({1'b0, gain_fixed});
    logic signed [13:0] pG = cG * $signed({1'b0, gain_fixed});
    logic signed [13:0] pB = cB * $signed({1'b0, gain_fixed});

    // 산술 시프트
    logic signed [11:0] sR2 = pR >>> 2;
    logic signed [11:0] sG2 = pG >>> 2;
    logic signed [11:0] sB2 = pB >>> 2;

    // 중간값 더하기
    logic signed [11:0] shR = sR2 + $signed({7'b0, mid});
    logic signed [11:0] shG = sG2 + $signed({7'b0, mid});
    logic signed [11:0] shB = sB2 + $signed({7'b0, mid});

    // 최종 4비트 출력
    always_comb begin
        if (shR > 12'sd15) red_port = 4'd15;
        else if (shR < 12'sd0) red_port = 4'd0;
        else red_port = shR[3:0];

        if (shG > 12'sd15) green_port = 4'd15;
        else if (shG < 12'sd0) green_port = 4'd0;
        else green_port = shG[3:0];

        if (shB > 12'sd15) blue_port = 4'd15;
        else if (shB < 12'sd0) blue_port = 4'd0;
        else blue_port = shB[3:0];
    end

   // assign red_port = ((rgb[11:8] - avg_data) * gain_fixed) >> 2 + avg_data;
   // assign green_port = ((rgb[7:4] - avg_data) * gain_fixed) >> 2 + avg_data;
   // assign blue_port = ((rgb[3:0] - avg_data) * gain_fixed) >> 2 + avg_data;
endmodule


module brightness_controller (
    input  logic        clk_25MHz,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 8:0] y_pixel,
    input  logic [11:0] gray_image,
    output logic [3:0] avg_data
);
    logic [11:0]
        reg_bright0,
        reg_bright1,
        reg_bright2,
        reg_bright3,
        reg_bright4,
        reg_bright5,
        reg_bright6,
        reg_bright7,
        reg_bright8,
        reg_bright9,
        reg_bright10,
        reg_bright11,
        reg_bright12,
        reg_bright13,
        reg_bright14,
        reg_bright15;
    logic [15:0] reg_data;
    
    assign avg_data = reg_data[11:8];

    always_ff @(posedge clk_25MHz, posedge reset) begin
        if (reset) begin
            reg_bright0 <= 0;
            reg_bright1 <= 0;
            reg_bright2 <= 0;
            reg_bright3 <= 0;
            reg_bright4 <= 0;
            reg_bright5 <= 0;
            reg_bright6 <= 0;
            reg_bright7 <= 0;
            reg_bright8 <= 0;
            reg_bright9 <= 0;
            reg_bright10 <= 0;
            reg_bright11 <= 0;
            reg_bright12 <= 0;
            reg_bright13 <= 0;
            reg_bright14 <= 0;
            reg_bright15 <= 0;
            reg_data <= 0;
        end else begin
            if (x_pixel == 40 && y_pixel == 30) begin
                reg_bright0 <= gray_image;
            end else if (x_pixel == 120 && y_pixel == 30) begin
                reg_bright1 <= gray_image;
            end else if (x_pixel == 200 && y_pixel == 30) begin
                reg_bright2 <= gray_image;
            end else if (x_pixel == 280 && y_pixel == 30) begin
                reg_bright3 <= gray_image;
            end else if (x_pixel == 40 && y_pixel == 90) begin
                reg_bright4 <= gray_image;
            end else if (x_pixel == 120 && y_pixel == 90) begin
                reg_bright5 <= gray_image;
            end else if (x_pixel == 200 && y_pixel == 90) begin
                reg_bright6 <= gray_image;
            end else if (x_pixel == 280 && y_pixel == 90) begin
                reg_bright7 <= gray_image;
            end else if (x_pixel == 40 && y_pixel == 150) begin
                reg_bright8 <= gray_image;
            end else if (x_pixel == 120 && y_pixel == 150) begin
                reg_bright9 <= gray_image;
            end else if (x_pixel == 200 && y_pixel == 150) begin
                reg_bright10 <= gray_image;
            end else if (x_pixel == 280 && y_pixel == 150) begin
                reg_bright11 <= gray_image;
            end else if (x_pixel == 41 && y_pixel == 210) begin
                reg_bright12 <= gray_image;
            end else if (x_pixel == 120 && y_pixel == 210) begin
                reg_bright13 <= gray_image;
            end else if (x_pixel == 200 && y_pixel == 210) begin
                reg_bright14 <= gray_image;
            end else if (x_pixel == 280 && y_pixel == 210) begin
                reg_bright15 <= gray_image;
            end else if (x_pixel == 319 && y_pixel == 239) begin
                reg_data <= ((reg_bright0 + reg_bright1 + reg_bright2 + reg_bright3 +
                reg_bright4 + reg_bright5 + reg_bright6 + reg_bright7 + reg_bright8 +
                reg_bright9 + reg_bright10 + reg_bright11+ reg_bright12+ reg_bright13+
                reg_bright14+ reg_bright15) >> 4);
            end 
        end
    end
endmodule