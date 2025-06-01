`timescale 1ns / 1ps

module tb_vga_switch_rgb_display;

    // global signals
    logic       clk;
    logic       reset;
    logic [3:0] rgb_sw;

    // ov7670 signals (from camera to DUT)
    wire        ov7670_x_clk;             // DUT에서 출력
    logic       ov7670_pixel_clk;         // 카메라 클럭: 테스트벤치에서 발생
    logic       ov7670_href;
    logic       ov7670_vsync;
    logic [7:0] ov7670_data;

    // export signals (to VGA monitor)
    wire        Hsync;
    wire        Vsync;
    wire [3:0]  vgaRed;
    wire [3:0]  vgaGreen;
    wire [3:0]  vgaBlue;

    // DUT 인스턴스
    OV7670_VGA_Display dut (
        .clk(clk),
        .reset(reset),
        .rgb_sw(rgb_sw),
        .ov7670_x_clk(ov7670_x_clk),
        .ov7670_pixel_clk(ov7670_pixel_clk),
        .ov7670_href(ov7670_href),
        .ov7670_vsync(ov7670_vsync),
        .ov7670_data(ov7670_data),
        .Hsync(Hsync),
        .Vsync(Vsync),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );

    // 메인 시스템 클럭 (10ns 주기, 100MHz)
    always #5 clk = ~clk;

    // OV7670 픽셀 클럭 (25MHz 가정)
    always #20 ov7670_pixel_clk = ~ov7670_pixel_clk;

    // 시뮬레이션 초기화 및 OV7670 입력 신호 생성
    initial begin
        clk = 0;
        ov7670_pixel_clk = 0;
        reset = 1;
        rgb_sw = 4'd0;
        ov7670_href = 0;
        ov7670_vsync = 1;  // 처음에 1, 나중에 떨어뜨림
        ov7670_data = 8'd0;

        #20 reset = 0;
        #20 rgb_sw = 4'd5;  // 빨강 + 초록 + 파랑이 다 켜지는 모드로 설정

        // 프레임 시작
        #100 ov7670_vsync = 0;

        repeat (200) begin
            @(posedge ov7670_pixel_clk);
            ov7670_href = 1;
            ov7670_data = $random % 256;  // 랜덤 픽셀 값
        end

        // 라인 종료
        @(posedge ov7670_pixel_clk);
        ov7670_href = 0;

        // 프레임 종료
        #50 ov7670_vsync = 1;

        // 시뮬레이션 종료
        #500 $finish;
    end

endmodule
