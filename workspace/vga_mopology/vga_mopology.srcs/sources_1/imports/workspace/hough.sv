module hough_vote_calculator #(
    parameter NUM_THETA_STEPS       = 180,
    parameter MAX_RHO_ABS           = 400, // 예시: 640x480 이미지의 대각선은 약 800, rho는 +-400
    parameter LUT_ADDR_WIDTH        = $clog2(NUM_THETA_STEPS),
    parameter RHO_ACCUM_WIDTH       = $clog2(2 * MAX_RHO_ABS),
    parameter COS_SIN_WIDTH         = 16, // 예: Q8.8 포맷이면 16비트 (부호1 + 정수7 + 소수8)
    parameter XY_WIDTH              = 10, // 예: 640 또는 480은 10비트 내
    parameter FIXED_POINT_SHIFT     = 8
) (
    input logic i_clk,
    input logic i_reset,

    // 현재 엣지 픽셀 정보
    input logic [XY_WIDTH-1:0] i_pixel_x,
    input logic [XY_WIDTH-1:0] i_pixel_y,
    input logic i_is_edge, // 이 모듈은 i_is_edge가 1일 때만 의미있게 동작한다고 가정
    input logic i_start_hough_for_pixel, // 이 픽셀에 대한 허프 변환 시작

    // Cos/Sin LUT 출력 (외부 ROM에서 읽어온 값)
    // 이 모듈이 theta_index를 주면, 외부 LUT에서 해당 값을 가져와야 함
    input logic signed [COS_SIN_WIDTH-1:0] i_cos_lut_data,
    input logic signed [COS_SIN_WIDTH-1:0] i_sin_lut_data,

    // 누적 배열 업데이트용 출력
    output logic [RHO_ACCUM_WIDTH-1:0] o_accum_addr_rho,
    output logic [LUT_ADDR_WIDTH-1:0]  o_accum_addr_theta, // theta 인덱스
    output logic o_accum_we, // 쓰기 인에이블 (투표)
    output logic o_busy // 현재 모듈이 특정 픽셀에 대해 theta 순회 중인지 여부
);

    // 내부 상태 및 레지스터
    typedef enum logic [1:0] {
        S_IDLE,
        S_CALC_RHO,
        S_WAIT_LUT // LUT에서 값 읽어오는 데 1클럭 지연이 있다면 필요
    } state_t;

    state_t current_state, next_state;

    logic [XY_WIDTH-1:0] r_pixel_x;
    logic [XY_WIDTH-1:0] r_pixel_y;
    logic [LUT_ADDR_WIDTH-1:0] r_current_theta_index;
    logic r_processing_pixel; // 현재 특정 픽셀을 처리 중인지 여부

    // Rho 계산 결과 (고정 소수점)
    logic signed [(XY_WIDTH + COS_SIN_WIDTH)-1:0] rho_intermediate;
    logic signed [RHO_ACCUM_WIDTH + FIXED_POINT_SHIFT -1 : 0] rho_scaled; // x*cos + y*sin (스케일링됨)
    logic signed [RHO_ACCUM_WIDTH-1:0] rho_final_index; // 최종 누적 배열 인덱스 (정수)

    // Theta 인덱스 카운터
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_current_theta_index <= '0;
        end else if (current_state == S_CALC_RHO) begin // 또는 S_WAIT_LUT에서 다음 상태로 갈 때
            if (r_current_theta_index == NUM_THETA_STEPS - 1) begin
                r_current_theta_index <= '0; // 한 픽셀에 대한 theta 순회 완료
            end else begin
                r_current_theta_index <= r_current_theta_index + 1;
            end
        end
    end

    // 현재 처리 중인 픽셀 좌표 저장
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_pixel_x <= '0;
            r_pixel_y <= '0;
            r_processing_pixel <= 1'b0;
        end else if (i_start_hough_for_pixel && i_is_edge && current_state == S_IDLE) begin
            r_pixel_x <= i_pixel_x;
            r_pixel_y <= i_pixel_y;
            r_processing_pixel <= 1'b1;
        end else if (current_state == S_CALC_RHO && r_current_theta_index == NUM_THETA_STEPS - 1) begin
            // 한 픽셀에 대한 모든 theta 처리 완료
            r_processing_pixel <= 1'b0;
        end
    end

    // 상태 머신
    always_ff @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        o_accum_we = 1'b0;
        // o_accum_addr_rho, o_accum_addr_theta는 S_CALC_RHO (또는 S_WAIT_LUT)에서 결정
        o_busy = r_processing_pixel;

        case (current_state)
            S_IDLE: begin
                if (i_start_hough_for_pixel && i_is_edge) begin
                    next_state = S_CALC_RHO; // LUT 지연 없으면 바로 CALC, 있으면 WAIT_LUT
                end
            end
            // S_WAIT_LUT: begin // 만약 LUT 읽기에 1클럭 지연이 있다면
            //    next_state = S_CALC_RHO;
            // end
            S_CALC_RHO: begin
                // rho = x*cos + y*sin 계산 (i_cos_lut_data, i_sin_lut_data 사용)
                // 이 계산은 조합 로직으로 이루어지거나, DSP 슬라이스를 사용하면 한 클럭에 가능

                // 현재 r_current_theta_index에 대한 cos, sin 값은 이전 클럭에 요청되어
                // i_cos_lut_data, i_sin_lut_data로 들어왔다고 가정 (LUT 지연 1클럭)
                // 또는, LUT 지연이 없다면 현재 r_current_theta_index로 바로 계산

                // ** Rho 계산 **
                // 곱셈: x * cos(theta) 와 y * sin(theta)
                // x,y는 unsigned, cos/sin은 signed. 결과는 signed.
                logic signed [(XY_WIDTH + COS_SIN_WIDTH)-1:0] term_x_cos;
                logic signed [(XY_WIDTH + COS_SIN_WIDTH)-1:0] term_y_sin;

                // 고정 소수점 곱셈 (결과의 소수점 위치 주의)
                // $signed()로 변환하여 곱셈
                term_x_cos = $signed(r_pixel_x) * i_cos_lut_data;
                term_y_sin = $signed(r_pixel_y) * i_sin_lut_data;
                rho_scaled = term_x_cos + term_y_sin; // 결과는 (XY_WIDTH + COS_SIN_WIDTH) 비트, 소수점 FIXED_POINT_SHIFT

                // 스케일 다운 (오른쪽 시프트) 및 반올림(옵션, 여기선 단순 절삭)
                // rho_final_index_temp의 부호도 고려해야 함
                logic signed [RHO_ACCUM_WIDTH + FIXED_POINT_SHIFT -1 : 0] rho_to_round;
                rho_to_round = rho_scaled;
                if (FIXED_POINT_SHIFT > 0) begin
                    // 간단한 반올림: (val + (1 << (SHIFT-1))) >> SHIFT
                    // 여기서는 단순 절삭으로 가정 (또는 signed shift)
                    rho_final_index = rho_to_round >>> FIXED_POINT_SHIFT;
                end else begin
                    rho_final_index = rho_to_round;
                end

                // rho_final_index를 누적 배열 주소로 변환 (offset 더하기)
                // 누적 배열은 0 ~ (2*MAX_RHO_ABS - 1)의 인덱스를 가짐
                // rho_final_index는 -MAX_RHO_ABS ~ +MAX_RHO_ABS 범위로 가정
                o_accum_addr_rho = rho_final_index + MAX_RHO_ABS;
                o_accum_addr_theta = r_current_theta_index;
                o_accum_we = 1'b1; // 투표!

                if (r_current_theta_index == NUM_THETA_STEPS - 1) begin
                    // 이 픽셀에 대한 모든 theta 처리 완료
                    if (i_start_hough_for_pixel && i_is_edge) begin // 다음 엣지 픽셀이 바로 들어오면
                        next_state = S_CALC_RHO; // 또는 S_WAIT_LUT
                    
                    end else begin
                        next_state = S_IDLE;
                    end
                end else begin
                    next_state = S_CALC_RHO; // 다음 theta 계산 (또는 S_WAIT_LUT)
                end
            end
            
            default: next_state = S_IDLE;
        endcase
    end

    // Cos/Sin LUT 주소는 r_current_theta_index를 사용 (만약 LUT가 이 모듈 외부에 있다면)
    // assign o_lut_addr_theta = r_current_theta_index; // LUT에 전달할 주소 (LUT 지연 고려)
    // 이 모듈에서는 i_cos_lut_data, i_sin_lut_data를 직접 받는다고 가정했음.
    // 실제로는 이 모듈이 theta 인덱스를 출력하고, LUT에서 값을 읽어온 후 다시 이 모듈로 들어오는 파이프라인 구성이 일반적.
    // 그 경우 S_WAIT_LUT 상태가 필요.

endmodule