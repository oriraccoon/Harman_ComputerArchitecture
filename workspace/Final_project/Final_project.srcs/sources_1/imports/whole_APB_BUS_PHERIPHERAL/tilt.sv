`timescale 1ns / 1ps

module tilt (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // IP input
    input  logic        tilt_sensor
);
    logic tdr;

    APB_tilt U_APB_Tilt (.*);

    tilt_sensor_controller #(
        .DEBOUNCE_COUNT(1_000_000)
    ) U_Tilt_CTRL (
        .clk          (PCLK),
        .reset        (PRESET),
        .tilt_sensor  (tilt_sensor),
        .tilt_detected(tdr)
    );
endmodule

module APB_tilt (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    input  logic        tdr
);
    logic [31:0] slv_reg0;  //, slv_reg1, slv_reg2, slv_reg3;

    assign slv_reg0[0] = tdr;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            // slv_reg0 <= 0;
            // slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;  //slv_reg0 <= PWDATA;
                        // 2'd1: slv_reg1 <= PWDATA;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0; 
                        // 2'd1: PRDATA <= slv_reg1;
                        // 2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

// module tilt_sensor_controller (
//     input  logic clk,           // 시스템 클럭
//     input  logic reset,         // 활성 낮음 리셋
//     input  logic tilt_sensor,   // 틸트 센서 입력 핀
//     output logic tilt_detected  // 기울기 감지 신호
// );

//     // 파라미터 정의
//     parameter DEBOUNCE_COUNT = 1_000_000;   // 디바운스 카운터 (클럭 주파수에 따라 조정 필요)

//     // 내부 신호 및 레지스터
//     logic
//         tilt_sensor_ff1,
//         tilt_sensor_ff2;  // 메타안정성 방지용 플립플롭
//     logic        tilt_sensor_debounced;  // 디바운스된 센서 신호
//     logic        tilt_sensor_prev;  // 이전 센서 상태
//     logic [31:0] debounce_counter;  // 디바운스 카운터
//     logic [31:0] alarm_counter;  // 알람 타이머 카운터

//     // 메타안정성 방지를 위한 2단 플립플롭
//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             tilt_sensor_ff1 <= 1'b0;
//             tilt_sensor_ff2 <= 1'b0;
//         end else begin
//             tilt_sensor_ff1 <= tilt_sensor;
//             tilt_sensor_ff2 <= tilt_sensor_ff1;
//         end
//     end

//     // 디바운싱 로직
//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             debounce_counter <= 32'd0;
//             tilt_sensor_debounced <= 1'b0;
//         end else begin
//             if (tilt_sensor_ff2 != tilt_sensor_debounced) begin
//                 // 센서 입력이 현재 디바운스된 값과 다르면 카운터 증가
//                 if (debounce_counter < DEBOUNCE_COUNT) begin
//                     debounce_counter <= debounce_counter + 1;
//                 end else begin
//                     // 카운터가 임계값에 도달하면 디바운스된 값 업데이트
//                     tilt_sensor_debounced <= tilt_sensor_ff2;
//                     debounce_counter <= 32'd0;
//                 end
//             end else begin
//                 // 센서 입력이 현재 디바운스된 값과 같으면 카운터 리셋
//                 debounce_counter <= 32'd0;
//             end
//         end
//     end

//     // 에지 감지 및 알람 제어
//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             tilt_sensor_prev <= 1'b0;
//             tilt_detected <= 1'b0;
//         end else begin
//             // 이전 상태 저장
//             tilt_sensor_prev <= tilt_sensor_debounced;

//             // 기울기 변화 감지 (어느 방향이든 변화 감지)
//             if (tilt_sensor_debounced != tilt_sensor_prev) begin
//                 tilt_detected <= 1'b1;

//             end else begin
//                 tilt_detected <= 1'b0;

//             end
//         end
//     end

// endmodule
module tilt_sensor_controller ( 
    input  logic clk,           // 시스템 클럭
    input  logic reset,         // 활성 낮음 리셋
    input  logic tilt_sensor,   // 틸트 센서 입력 핀
    output logic tilt_detected  // 기울기 감지 신호
);

    // 파라미터 정의
    parameter DEBOUNCE_COUNT = 1_000_000;   // 디바운스 카운터

    // 내부 신호 및 레지스터
    logic tilt_sensor_ff1, tilt_sensor_ff2;  // 메타안정성 방지용 플립플롭
    logic tilt_sensor_debounced;             // 디바운스된 센서 신호
    logic tilt_sensor_prev;                  // 이전 센서 상태
    logic [31:0] debounce_counter;           // 디바운스 카운터

    // 메타안정성 방지를 위한 2단 플립플롭
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tilt_sensor_ff1 <= 1'b0;
            tilt_sensor_ff2 <= 1'b0;
        end else begin
            tilt_sensor_ff1 <= tilt_sensor;
            tilt_sensor_ff2 <= tilt_sensor_ff1;
        end
    end

    // 디바운싱 로직
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            debounce_counter <= 32'd0;
            tilt_sensor_debounced <= 1'b0; 
        end else begin
            if (tilt_sensor_ff2 != tilt_sensor_debounced) begin
                // 센서 입력이 현재 디바운스된 값과 다르면 카운터 증가
                if (debounce_counter < DEBOUNCE_COUNT) begin
                    debounce_counter <= debounce_counter + 1;
                end else begin
                    // 카운터가 임계값에 도달하면 디바운스된 값 업데이트
                    tilt_sensor_debounced <= tilt_sensor_ff2;
                    debounce_counter <= 32'd0;
                end
            end else begin
                // 센서 입력이 현재 디바운스된 값과 같으면 카운터 리셋
                debounce_counter <= 32'd0;
            end
        end
    end

    // 중요한 변경: 틸트 센서 상태 자체를 출력
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tilt_detected <= 1'b0;
        end else begin
            // 센서 상태 자체를 출력 (변화 감지 대신 상태 자체 사용)
            tilt_detected <= tilt_sensor_debounced;
        end 
    end

endmodule
