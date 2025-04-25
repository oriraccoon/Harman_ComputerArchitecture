`timescale 1ns / 1ps

module tb_Ultrasonic_Periph;

    // 클럭 및 리셋
    logic        PCLK;
    logic        PRESET;

    // APB 인터페이스 신호
    logic [3:0]  PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    wire  [31:0] PRDATA;
    wire         PREADY;

    // 초음파 신호
    logic        echo;
    wire         trig;

    // DUT 인스턴스
    Ultrasonic_Periph dut (
        .PCLK    (PCLK),
        .PRESET  (PRESET),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PWRITE  (PWRITE),
        .PENABLE (PENABLE),
        .PSEL    (PSEL),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .echo    (echo),
        .trig    (trig)
    );

    // 클럭 생성 (50MHz → 20ns)
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    // 초기화
    initial begin
        PRESET = 1;
        PADDR = 0;
        PWDATA = 0;
        PWRITE = 0;
        PENABLE = 0;
        PSEL = 0;
        echo = 0;

        #100;
        PRESET = 0;

        // 트리거 신호 기다림
        wait (trig == 1);
        $display(">> TRIG detected at %t ns", $time);
        
        // Echo 시뮬레이션 (예: 약 20cm 거리 ≈ 1160us 왕복 시간)
        // (속도: 343m/s → 1cm = 약 58us)
        #(20000);  // Echo HIGH duration (20cm 왕복 ≈ 1160us)
        echo = 1;
        #(116000);
        echo = 0;
        $display(">> ECHO simulated from %t to %t ns", $time - 1160, $time);

        // 측정 완료될 때까지 대기 (0.5초 간격 측정 루프)
        #(500_000);

        // APB 읽기 수행 (센티미터 거리값 읽기)
        apb_read(4'd0);  // slv_reg0 (idr 값 저장 위치)
        $display(">> PRDATA (distance in cm) = %d", PRDATA);

        #100;
        $finish;
    end

    // APB 읽기 task
    task apb_read(input [3:0] addr);
    begin
        @(posedge PCLK);
        PADDR = addr;
        PWRITE = 0;
        PSEL = 1;
        PENABLE = 0;

        @(posedge PCLK);
        PENABLE = 1;

        // Wait for PREADY
        wait (PREADY == 1);
        @(posedge PCLK);

        // Disable bus
        PSEL = 0;
        PENABLE = 0;
    end
    endtask

endmodule
