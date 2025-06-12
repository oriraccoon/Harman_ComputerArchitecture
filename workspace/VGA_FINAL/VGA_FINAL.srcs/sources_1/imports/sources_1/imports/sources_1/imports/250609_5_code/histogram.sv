`timescale 1ns / 1ps
module histogram (
    input              clk,
    input              reset,
    input        [9:0] x_pixel,
    input        [9:0] y_pixel,
    input  logic [3:0] red_port_after,        // 그레이스케일 값 입력
    input  logic       DE1,
    input  logic       DE2,
    input  logic       v_sync,
    output logic [3:0] red_port_hist,
    output logic [3:0] green_port_hist,
    output logic [3:0] blue_port_hist,
    input  logic       DEhorizonLine,
    input  logic       DEverticalLine,
    input  logic       DEhist0,
    input  logic       DEhist1,
    input  logic       DEhist2,
    input  logic       DEhist3,
    input  logic       DEhist4,
    input  logic       DEhist5,
    input  logic       DEhist6,
    input  logic       DEhist7, 
    input  logic       DEhist8,
    input  logic       DEhist9,
    input  logic       DEhist10,
    input  logic       DEhist11,
    input  logic       DEhist12,
    input  logic       DEhist13,
    input  logic       DEhist14,
    input  logic       DEhist15,
    input  logic       DEhistFont,
    output logic [7:0] bar_height_hist[0:15]  // 최종 막대 높이 : 업데이트 주기 10프레임
);

    // 입력 신호 레지스터링 (타이밍 개선)
    logic [3:0] red_port_after_reg;
    logic [3:0] red_port_after_reg_dly; 
    logic       DE1_reg;
    logic       DE1_reg_dly;         
    logic       DE2_reg;
    logic       DE2_reg_dly;           

    localparam   HEIGHT_MAX = 220;
    localparam   PIXEL_COUNTER = 350;  // 이 픽셀 수마다 막대 높이 1 증가

    logic [16:0] pixel_counter[0:15];         // 막대 높이 1 증가를 위한 임시 픽셀 카운터
    logic [7:0]  bar_height_hist_calc[0:15]; // 막대 최종높이
    logic        v_sync_before;
    logic        v_sync_rising_detector;  // v_sync 상승 엣지 펄스
    logic [3:0]  frame_counter;           // 0-9 프레임 카운터
    logic        frame_10_signal;         // 10프레임마다 발생하는 신호

    logic [3:0] r_temp, g_temp, b_temp; //rgb 임시공간
    logic choice_bar; // 현재 픽셀 위치에 막대를 그릴지 여부
    // 텍스트 폰트 관리용
    logic [12:0] text_addr;       
    logic [15:0] text_data_out;

    textfont_rom U_TextFontRom (
        .addr(text_addr),
        .data(text_data_out)
    );

    //입력 신호 딜레이
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            red_port_after_reg <= 4'b0;
            red_port_after_reg_dly <= 4'b0;
            DE1_reg            <= 1'b0;
            DE1_reg_dly        <= 1'b0;
            DE2_reg            <= 1'b0;
            DE2_reg_dly        <= 1'b0;
        end else begin
            red_port_after_reg <= red_port_after;
            red_port_after_reg_dly <= red_port_after_reg;
            DE1_reg            <= DE1;
            DE1_reg_dly        <= DE1_reg;
            DE2_reg            <= DE2;
            DE2_reg_dly        <= DE2_reg;
        end
    end

    // v_sync 상승 엣지 감지
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin v_sync_before <= 1'b1; end
        else begin v_sync_before <= v_sync; end 
    end
    assign v_sync_rising_detector = !v_sync_before && v_sync;

    // v_sync 상승 엣지를 사용, 10프레임 마다 신호
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin frame_counter <= 4'd0; end
        else if (v_sync_rising_detector) begin
            if (frame_counter == 4'd9) begin frame_counter <= 4'd0; end
            else begin frame_counter <= frame_counter + 1; end
        end
    end
    assign frame_10_signal = (frame_counter == 4'd0) && v_sync_rising_detector;

    //막대높이계산
    // 1. 10프레임마다 막대 높이 계산
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 16; i = i + 1) begin
                pixel_counter[i] <= 17'b0;
                bar_height_hist_calc[i] <= 8'd0;
            end
        end else if (frame_10_signal) begin //10프레임 시작시 초기화
            for (int i = 0; i < 16; i = i + 1) begin
                pixel_counter[i] <= 17'b0;
                bar_height_hist_calc[i] <= 8'd0;
            end
        end else if (DE1_reg_dly && (frame_counter == 4'd1)) begin //10프레임 & v싱크 상승시
            if (red_port_after_reg_dly < 16) begin
                if (pixel_counter[red_port_after_reg_dly] == PIXEL_COUNTER - 1) begin
                    pixel_counter[red_port_after_reg_dly] <= 17'b0; //350만큼 들어오면 픽셀 카운터 리셋하고
                    if (bar_height_hist_calc[red_port_after_reg_dly] < HEIGHT_MAX) begin 
                        bar_height_hist_calc[red_port_after_reg_dly] <= bar_height_hist_calc[red_port_after_reg_dly] + 1; // 막대높이 1증가
                    end
                end else begin
                    pixel_counter[red_port_after_reg_dly] <= pixel_counter[red_port_after_reg_dly] + 1;
                end
            end
        end
    end

    // 2. 최종 막대 높이 업데이트
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 16; i=i+1) begin bar_height_hist[i] <= 8'd0; end
        end else if (frame_10_signal) begin 
            for (int i = 0; i < 16; i=i+1) begin
                bar_height_hist[i] <= bar_height_hist_calc[i];
            end
        end
    end

    // 3. 폰트 처리
    always_comb begin
        logic [7:0] h_counter_font, v_counter_font;
        if (DEhistFont) begin
            localparam FONT_AREA_H_START = 35;
            localparam FONT_AREA_V_START = 460;
            localparam FONT_AREA_WIDTH   = 250;

            h_counter_font = x_pixel - FONT_AREA_H_START;
            v_counter_font = y_pixel - FONT_AREA_V_START;
            text_addr = v_counter_font * FONT_AREA_WIDTH + h_counter_font;
        end else begin
            text_addr = 13'd0;
        end
    end

    //RGB 출력 관리
    always_comb begin

        if (DEhistFont) begin //텍스트
            r_temp = text_data_out[15:12];
            g_temp = text_data_out[10:7];
            b_temp = text_data_out[4:1];
        end else if (DE2) begin //히스토그램
            r_temp = 4'b0000;
            g_temp = 4'b0000;
            b_temp = 4'b0000;
            choice_bar = 1'b0; 
            if      (DEhist0  && bar_height_hist[0]  > 0) choice_bar = 1'b1;
            else if (DEhist1  && bar_height_hist[1]  > 0) choice_bar = 1'b1;
            else if (DEhist2  && bar_height_hist[2]  > 0) choice_bar = 1'b1;
            else if (DEhist3  && bar_height_hist[3]  > 0) choice_bar = 1'b1;
            else if (DEhist4  && bar_height_hist[4]  > 0) choice_bar = 1'b1;
            else if (DEhist5  && bar_height_hist[5]  > 0) choice_bar = 1'b1;
            else if (DEhist6  && bar_height_hist[6]  > 0) choice_bar = 1'b1;
            else if (DEhist7  && bar_height_hist[7]  > 0) choice_bar = 1'b1;
            else if (DEhist8  && bar_height_hist[8]  > 0) choice_bar = 1'b1;
            else if (DEhist9  && bar_height_hist[9]  > 0) choice_bar = 1'b1;
            else if (DEhist10 && bar_height_hist[10] > 0) choice_bar = 1'b1;
            else if (DEhist11 && bar_height_hist[11] > 0) choice_bar = 1'b1;
            else if (DEhist12 && bar_height_hist[12] > 0) choice_bar = 1'b1;
            else if (DEhist13 && bar_height_hist[13] > 0) choice_bar = 1'b1;
            else if (DEhist14 && bar_height_hist[14] > 0) choice_bar = 1'b1;
            else if (DEhist15 && bar_height_hist[15] > 0) choice_bar = 1'b1;
            if ( (DEhist0 || DEhist1 || DEhist2 || DEhist3 || DEhist4 || DEhist5 || DEhist6 || DEhist7 ||
                   DEhist8 || DEhist9 || DEhist10 || DEhist11 || DEhist12 || DEhist13 || DEhist14 || DEhist15)
                  && choice_bar ) begin
                {r_temp, g_temp, b_temp} = {4'b1000, 4'b1000, 4'b1000};
            end

            // 기준선 그리기
            if (DEhorizonLine || DEverticalLine) begin
                {r_temp, g_temp, b_temp} = {4'b1111, 4'b1111, 4'b1111}; // 흰색
            end
        end else begin
            {r_temp, g_temp, b_temp} = {4'bz, 4'bz, 4'bz};
        end
        // 최종 RGB 
        red_port_hist   = r_temp;
        green_port_hist = g_temp;
        blue_port_hist  = b_temp;
    end

endmodule


module textfont_rom (
    input  logic [12:0] addr,
    output logic [15:0] data
);


    logic [15:0] rom [0:250*20-1]; 

    initial begin
        $readmemh("textfont.mem", rom);
    end

    assign data = rom[addr];

endmodule


module histogram2 (
    input              clk,
    input              reset,
    input        [9:0] x_pixel,
    input        [9:0] y_pixel,
    input  logic [3:0] red_port_after,        // 그레이스케일 값 입력
    input  logic       DE1,
    input  logic       DE2,
    input  logic       v_sync,
    output logic [3:0] red_port_hist,
    output logic [3:0] green_port_hist,
    output logic [3:0] blue_port_hist,
    input  logic       DEhorizonLine,
    input  logic       DEverticalLine,
    input  logic       DEhist0,
    input  logic       DEhist1,
    input  logic       DEhist2,
    input  logic       DEhist3,
    input  logic       DEhist4,
    input  logic       DEhist5,
    input  logic       DEhist6,
    input  logic       DEhist7, 
    input  logic       DEhist8,
    input  logic       DEhist9,
    input  logic       DEhist10,
    input  logic       DEhist11,
    input  logic       DEhist12,
    input  logic       DEhist13,
    input  logic       DEhist14,
    input  logic       DEhist15,
    input  logic       DEhistFont,
    output logic [7:0] bar_height_hist[0:15]  // 최종 막대 높이 : 업데이트 주기 10프레임
);

    // 입력 신호 레지스터링 (타이밍 개선)
    logic [3:0] red_port_after_reg;
    logic [3:0] red_port_after_reg_dly; 
    logic       DE1_reg;
    logic       DE1_reg_dly;         
    logic       DE2_reg;
    logic       DE2_reg_dly;           

    localparam   HEIGHT_MAX = 220;
    localparam   PIXEL_COUNTER = 350;  // 이 픽셀 수마다 막대 높이 1 증가

    logic [16:0] pixel_counter[0:15];         // 막대 높이 1 증가를 위한 임시 픽셀 카운터
    logic [7:0]  bar_height_hist_calc[0:15]; // 막대 최종높이
    logic        v_sync_before;
    logic        v_sync_rising_detector;  // v_sync 상승 엣지 펄스
    logic [3:0]  frame_counter;           // 0-9 프레임 카운터
    logic        frame_10_signal;         // 10프레임마다 발생하는 신호

    logic [3:0] r_temp, g_temp, b_temp; //rgb 임시공간
    logic choice_bar; // 현재 픽셀 위치에 막대를 그릴지 여부
    // 텍스트 폰트 관리용
    logic [12:0] text_addr;       
    logic [15:0] text_data_out;

    textfont_rom U_TextFontRom (
        .addr(text_addr),
        .data(text_data_out)
    );

    //입력 신호 딜레이
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            red_port_after_reg <= 4'b0;
            red_port_after_reg_dly <= 4'b0;
            DE1_reg            <= 1'b0;
            DE1_reg_dly        <= 1'b0;
            DE2_reg            <= 1'b0;
            DE2_reg_dly        <= 1'b0;
        end else begin
            red_port_after_reg <= red_port_after;
            red_port_after_reg_dly <= red_port_after_reg;
            DE1_reg            <= DE1;
            DE1_reg_dly        <= DE1_reg;
            DE2_reg            <= DE2;
            DE2_reg_dly        <= DE2_reg;
        end
    end

    // v_sync 상승 엣지 감지
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin v_sync_before <= 1'b1; end
        else begin v_sync_before <= v_sync; end 
    end
    assign v_sync_rising_detector = !v_sync_before && v_sync;

    // v_sync 상승 엣지를 사용, 10프레임 마다 신호
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin frame_counter <= 4'd0; end
        else if (v_sync_rising_detector) begin
            if (frame_counter == 4'd9) begin frame_counter <= 4'd0; end
            else begin frame_counter <= frame_counter + 1; end
        end
    end
    assign frame_10_signal = (frame_counter == 4'd0) && v_sync_rising_detector;

    //막대높이계산
    // 1. 10프레임마다 막대 높이 계산
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 16; i = i + 1) begin
                pixel_counter[i] <= 17'b0;
                bar_height_hist_calc[i] <= 8'd0;
            end
        end else if (frame_10_signal) begin //10프레임 시작시 초기화
            for (int i = 0; i < 16; i = i + 1) begin
                pixel_counter[i] <= 17'b0;
                bar_height_hist_calc[i] <= 8'd0;
            end
        end else if (DE1_reg_dly && (frame_counter == 4'd1)) begin //10프레임 & v싱크 상승시
            if (red_port_after_reg_dly < 16) begin
                if (pixel_counter[red_port_after_reg_dly] == PIXEL_COUNTER - 1) begin
                    pixel_counter[red_port_after_reg_dly] <= 17'b0; //350만큼 들어오면 픽셀 카운터 리셋하고
                    if (bar_height_hist_calc[red_port_after_reg_dly] < HEIGHT_MAX) begin 
                        bar_height_hist_calc[red_port_after_reg_dly] <= bar_height_hist_calc[red_port_after_reg_dly] + 1; // 막대높이 1증가
                    end
                end else begin
                    pixel_counter[red_port_after_reg_dly] <= pixel_counter[red_port_after_reg_dly] + 1;
                end
            end
        end
    end

    // 2. 최종 막대 높이 업데이트
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 16; i=i+1) begin bar_height_hist[i] <= 8'd0; end
        end else if (frame_10_signal) begin 
            for (int i = 0; i < 16; i=i+1) begin
                bar_height_hist[i] <= bar_height_hist_calc[i];
            end
        end
    end

    // 3. 폰트 처리
    always_comb begin
        logic [7:0] h_counter_font, v_counter_font;
        if (DEhistFont) begin
            localparam FONT_AREA_H_START = 355;
            localparam FONT_AREA_V_START = 460;
            localparam FONT_AREA_WIDTH   = 250;

            h_counter_font = x_pixel - FONT_AREA_H_START;
            v_counter_font = y_pixel - FONT_AREA_V_START;
            text_addr = v_counter_font * FONT_AREA_WIDTH + h_counter_font;
        end else begin
            text_addr = 13'd0;
        end
    end

    //RGB 출력 관리
    always_comb begin

        if (DEhistFont) begin //텍스트
            r_temp = text_data_out[15:12];
            g_temp = text_data_out[10:7];
            b_temp = text_data_out[4:1];
        end else if (DE2) begin //히스토그램
            r_temp = 4'b0000;
            g_temp = 4'b0000;
            b_temp = 4'b0000;
            choice_bar = 1'b0; 
            if      (DEhist0  && bar_height_hist[0]  > 0) choice_bar = 1'b1;
            else if (DEhist1  && bar_height_hist[1]  > 0) choice_bar = 1'b1;
            else if (DEhist2  && bar_height_hist[2]  > 0) choice_bar = 1'b1;
            else if (DEhist3  && bar_height_hist[3]  > 0) choice_bar = 1'b1;
            else if (DEhist4  && bar_height_hist[4]  > 0) choice_bar = 1'b1;
            else if (DEhist5  && bar_height_hist[5]  > 0) choice_bar = 1'b1;
            else if (DEhist6  && bar_height_hist[6]  > 0) choice_bar = 1'b1;
            else if (DEhist7  && bar_height_hist[7]  > 0) choice_bar = 1'b1;
            else if (DEhist8  && bar_height_hist[8]  > 0) choice_bar = 1'b1;
            else if (DEhist9  && bar_height_hist[9]  > 0) choice_bar = 1'b1;
            else if (DEhist10 && bar_height_hist[10] > 0) choice_bar = 1'b1;
            else if (DEhist11 && bar_height_hist[11] > 0) choice_bar = 1'b1;
            else if (DEhist12 && bar_height_hist[12] > 0) choice_bar = 1'b1;
            else if (DEhist13 && bar_height_hist[13] > 0) choice_bar = 1'b1;
            else if (DEhist14 && bar_height_hist[14] > 0) choice_bar = 1'b1;
            else if (DEhist15 && bar_height_hist[15] > 0) choice_bar = 1'b1;
            if ( (DEhist0 || DEhist1 || DEhist2 || DEhist3 || DEhist4 || DEhist5 || DEhist6 || DEhist7 ||
                   DEhist8 || DEhist9 || DEhist10 || DEhist11 || DEhist12 || DEhist13 || DEhist14 || DEhist15)
                  && choice_bar ) begin
                {r_temp, g_temp, b_temp} = {4'b1000, 4'b1000, 4'b1000};
            end

            // 기준선 그리기
            if (DEhorizonLine || DEverticalLine) begin
                {r_temp, g_temp, b_temp} = {4'b1111, 4'b1111, 4'b1111}; // 흰색
            end
        end else begin
            {r_temp, g_temp, b_temp} = {4'bz, 4'bz, 4'bz};
        end
        // 최종 RGB 
        red_port_hist   = r_temp;
        green_port_hist = g_temp;
        blue_port_hist  = b_temp;
    end

endmodule


module textfont_rom2 (
    input  logic [12:0] addr,
    output logic [15:0] data
);


    logic [15:0] rom [0:250*20-1]; 

    initial begin
        $readmemh("textfont.mem", rom);
    end

    assign data = rom[addr];

endmodule