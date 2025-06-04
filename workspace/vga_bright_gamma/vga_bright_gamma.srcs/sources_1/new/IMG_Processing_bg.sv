`timescale 1ns / 1ps

module IMG_Processing_bg (
    // --- Global Inputs ---
    input logic clk,
    input logic reset,
    input logic en,     // 전체 모듈 동작을 위한 Enable

    // --- Data Path ---
    input  logic [11:0] i_data,  // 원본 12-bit RGB 입력
    output logic [11:0] o_data,  // 최종 12-bit RGB 출력

    // --- Control Inputs (Buttons separated for clarity) ---
    input logic bright_up_btn,    // 밝기 증가 버튼
    input logic bright_down_btn,  // 밝기 감소 버튼
    input logic gamma_up_btn,     // 감마 모드 변경 (Up) 버튼
    input logic gamma_down_btn,   // 감마 모드 변경 (Down) 버튼

    // --- Status Output ---
    output logic o_en  // 최종 출력 Enable (원본의 ge)
);

    //================================================================
    // 내부 신호 및 상태 변수 선언
    //================================================================

    // --- 중간 데이터 및 Enable 신호 (두 모듈 연결부) ---
    logic [11:0] bright_corrected_data; // 밝기 조절 후 데이터 (원본의 BRIGHT_RGB444_data)
    logic bright_en;  // 밝기 조절 Enable (원본의 be)

    // --- 버튼 Edge-Trigger 신호 ---
    logic r_bright_up_btn, r_bright_down_btn;
    logic r_gamma_up_btn, r_gamma_down_btn;

    // --- 감마 필터 관련 ---
    typedef enum {
        G1_0,
        G1_8,
        G2_2,
        G0_5
    } state_e;
    state_e gamma_state;

    // 감마 LUT 출력 와이어
    logic [3:0] r_gamma_1_0, g_gamma_1_0, b_gamma_1_0;
    logic [3:0] r_gamma_1_8, g_gamma_1_8, b_gamma_1_8;
    logic [3:0] r_gamma_2_2, g_gamma_2_2, b_gamma_2_2;
    logic [3:0] r_gamma_0_5, g_gamma_0_5, b_gamma_0_5;


    //================================================================
    // 서브모듈 인스턴스
    //================================================================

    // --- 버튼 디바운싱 및 Edge 감지 ---
    btn_edge_trigger U_BRIGHT_UP_BTN (
        .clk  (clk),
        .rst  (reset),
        .i_btn(bright_up_btn),
        .o_btn(r_bright_up_btn)
    );
    btn_edge_trigger U_BRIGHT_DOWN_BTN (
        .clk  (clk),
        .rst  (reset),
        .i_btn(bright_down_btn),
        .o_btn(r_bright_down_btn)
    );
    btn_edge_trigger U_GAMMA_UP_BTN (
        .clk  (clk),
        .rst  (reset),
        .i_btn(gamma_up_btn),
        .o_btn(r_gamma_up_btn)
    );
    btn_edge_trigger U_GAMMA_DOWN_BTN (
        .clk  (clk),
        .rst  (reset),
        .i_btn(gamma_down_btn),
        .o_btn(r_gamma_down_btn)
    );

    // --- 감마 보정 LUT (Look-Up Table) 인스턴스 ---
    // 입력으로 'bright_corrected_data'를 사용
    // 1.0 (Linear)
    gamma_rom_4bit_linear_g1_0 lut_r_g1_0 (
        .in_val(bright_corrected_data[11:8]),
        .gamma_corrected(r_gamma_1_0)
    );
    gamma_rom_4bit_linear_g1_0 lut_g_g1_0 (
        .in_val(bright_corrected_data[7:4]),
        .gamma_corrected(g_gamma_1_0)
    );
    gamma_rom_4bit_linear_g1_0 lut_b_g1_0 (
        .in_val(bright_corrected_data[3:0]),
        .gamma_corrected(b_gamma_1_0)
    );
    // 1.8
    gamma_rom_4bit_g1_8 lut_r_g1_8 (
        .in_val(bright_corrected_data[11:8]),
        .gamma_corrected(r_gamma_1_8)
    );
    gamma_rom_4bit_g1_8 lut_g_g1_8 (
        .in_val(bright_corrected_data[7:4]),
        .gamma_corrected(g_gamma_1_8)
    );
    gamma_rom_4bit_g1_8 lut_b_g1_8 (
        .in_val(bright_corrected_data[3:0]),
        .gamma_corrected(b_gamma_1_8)
    );
    // 2.2
    gamma_rom_4bit_g2_2 lut_r_g2_2 (
        .in_val(bright_corrected_data[11:8]),
        .gamma_corrected(r_gamma_2_2)
    );
    gamma_rom_4bit_g2_2 lut_g_g2_2 (
        .in_val(bright_corrected_data[7:4]),
        .gamma_corrected(g_gamma_2_2)
    );
    gamma_rom_4bit_g2_2 lut_b_g2_2 (
        .in_val(bright_corrected_data[3:0]),
        .gamma_corrected(b_gamma_2_2)
    );
    // 0.5
    gamma_rom_4bit_g0_5 lut_r_g0_5 (
        .in_val(bright_corrected_data[11:8]),
        .gamma_corrected(r_gamma_0_5)
    );
    gamma_rom_4bit_g0_5 lut_g_g0_5 (
        .in_val(bright_corrected_data[7:4]),
        .gamma_corrected(g_gamma_0_5)
    );
    gamma_rom_4bit_g0_5 lut_b_g0_5 (
        .in_val(bright_corrected_data[3:0]),
        .gamma_corrected(b_gamma_0_5)
    );


    //================================================================
    // 동작 로직
    //================================================================

    // --- 1. 밝기 조절 로직 (From Bright_Controller) ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            bright_corrected_data <= 12'd0;
            bright_en             <= 1'b0;
        end else begin
            if (en) begin
                bright_en <= 1'b1;
                if (r_bright_up_btn) begin
                    // R 채널 밝기 증가 (최대값 15에서 고정)
                    if (i_data[11:8] == 4'hF)
                        bright_corrected_data[11:8] <= 4'hF;
                    else bright_corrected_data[11:8] <= i_data[11:8] + 1;

                    // G 채널 밝기 증가 (최대값 15에서 고정)
                    if (i_data[7:4] >= 4'hE) bright_corrected_data[7:4] <= 4'hF;
                    else bright_corrected_data[7:4] <= i_data[7:4] + 2;

                    // B 채널 밝기 증가 (최대값 15에서 고정)
                    if (i_data[3:0] == 4'hF) bright_corrected_data[3:0] <= 4'hF;
                    else bright_corrected_data[3:0] <= i_data[3:0] + 1;
                end else if (r_bright_down_btn) begin
                    // R 채널 밝기 감소 (최소값 0에서 고정)
                    if (i_data[11:8] == 4'h0)
                        bright_corrected_data[11:8] <= 4'h0;
                    else bright_corrected_data[11:8] <= i_data[11:8] - 1;

                    // G 채널 밝기 감소 (최소값 0에서 고정)
                    if (i_data[7:4] <= 4'h1) bright_corrected_data[7:4] <= 4'h0;
                    else bright_corrected_data[7:4] <= i_data[7:4] - 2;

                    // B 채널 밝기 감소 (최소값 0에서 고정)
                    if (i_data[3:0] == 4'h0) bright_corrected_data[3:0] <= 4'h0;
                    else bright_corrected_data[3:0] <= i_data[3:0] - 1;
                end else begin
                    // 버튼 입력이 없으면 원본 데이터 통과
                    bright_corrected_data <= i_data;
                end
            end else begin
                bright_en <= 1'b0;
                // en이 0일 때 데이터는 이전 값을 유지
            end
        end
    end

    // --- 2. 감마 상태 제어 로직 (From Gamma_Filter) ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            gamma_state <= G1_0;  // 리셋 시 기본 상태로 초기화
            o_en        <= 1'b0;
        end else begin
            // 이 로직은 밝기 조절이 Enable되었을 때만 동작 (원본 연결 구조 반영)
            if (bright_en) begin
                o_en <= 1'b1;
                if (r_gamma_up_btn) begin
                    case (gamma_state)
                        G1_0: gamma_state <= G1_8;
                        G1_8: gamma_state <= G2_2;
                        G2_2: gamma_state <= G0_5;
                        G0_5: gamma_state <= G1_0;
                    endcase
                end
                if (r_gamma_down_btn) begin // if-else if가 아닌 별도 if문 사용 (동시 누름 방지)
                    case (gamma_state)
                        G1_0: gamma_state <= G0_5;
                        G1_8: gamma_state <= G1_0;
                        G2_2: gamma_state <= G1_8;
                        G0_5: gamma_state <= G2_2;
                    endcase
                end
            end else begin
                o_en <= 1'b0;
                // bright_en이 0일 때 상태는 이전 값을 유지
            end
        end
    end

    // --- 3. 최종 출력 선택 로직 (From Gamma_Filter) ---
    // 현재 감마 상태(gamma_state)에 따라 LUT 출력을 선택하여 최종 o_data 생성
    always_comb begin
        case (gamma_state)
            G1_0: o_data = {r_gamma_1_0, g_gamma_1_0, b_gamma_1_0};
            G1_8: o_data = {r_gamma_1_8, g_gamma_1_8, b_gamma_1_8};
            G2_2: o_data = {r_gamma_2_2, g_gamma_2_2, b_gamma_2_2};
            G0_5: o_data = {r_gamma_0_5, g_gamma_0_5, b_gamma_0_5};
            default:
            o_data = {r_gamma_1_0, g_gamma_1_0, b_gamma_1_0};  // 기본값
        endcase
    end

endmodule
