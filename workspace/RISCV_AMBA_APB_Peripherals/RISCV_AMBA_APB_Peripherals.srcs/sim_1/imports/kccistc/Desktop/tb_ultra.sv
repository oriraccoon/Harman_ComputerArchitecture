`timescale 1ns/1ps

module tb_Ultrasonic_IP;

    logic PCLK;
    logic PRESET;
    logic echo;
    logic [$clog2(400)-1:0] idr;
    logic trig;

    // DUT 인스턴스
    Ultrasonic_IP dut (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .echo(echo),
        .idr(idr),
        .trig(trig)
    );

    // PCLK 생성: 10ns 주기 (100MHz)
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    initial begin
        // 초기화
        PRESET = 1;
        echo = 0;
        #20;
        PRESET = 0;

        // o_PCLK으로부터 trig 발생까지 기다림
        wait(trig == 1);
        $display("[INFO] trig asserted at time %t", $time);

        // trig 유지
        wait(trig == 0);
        $display("[INFO] trig deasserted at time %t", $time);

        // echo rising edge
        #500;  // 약간의 딜레이 후 echo HIGH (초음파 반사됨)
        echo = 1;
        $display("[TEST] echo HIGH at time %t", $time);

        // 일정 시간 유지 (예: 1740ns = 30cm 거리 기준 100MHz에서 약 174 cycles)
        #1740;
        echo = 0;
        $display("[TEST] echo LOW at time %t", $time);

        // 거리 계산 결과 출력
        #1000;
        $display("[RESULT] Measured distance (idr): %d cm", idr);

        // 시뮬레이션 종료
        #500;
        $finish;
    end

endmodule
