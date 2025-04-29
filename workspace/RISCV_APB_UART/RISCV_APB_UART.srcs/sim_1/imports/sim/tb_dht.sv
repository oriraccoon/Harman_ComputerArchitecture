`timescale 1ns/1ps

module Humidity_Periph_tb;

    logic PCLK;
    logic PRESET;
    logic [3:0] PADDR;
    logic [31:0] PWDATA;
    logic PWRITE;
    logic PENABLE;
    logic PSEL;
    logic [31:0] PRDATA;
    logic PREADY;
    tri dht_io;     // inout은 tri로 선언

    logic dht_io_drv;   // DHT11 모델이 구동할 신호
    logic dht_io_drv_en;
    assign dht_io = (dht_io_drv_en) ? dht_io_drv : 1'bz;

    // DUT 인스턴스
    Humidity_Periph dut (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .dht_io(dht_io)
    );

    // Clock 생성 (100MHz)
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    // 초기화 및 시뮬레이션 시나리오
    initial begin
        // 초기값
        PRESET = 1;
        PADDR = 0;
        PWDATA = 0;
        PWRITE = 0;
        PENABLE = 0;
        PSEL = 0;
        dht_io_drv_en = 0;
        dht_io_drv = 1;

        #20;
        PRESET = 0;

        // 기다리기 (센서 초기화 및 데이터 수집 시간)
        repeat(40_000) @(posedge PCLK); // 충분히 대기 (센서 주기 기다림)

        // 습도 데이터 읽기 요청
        APB_Read(4'h0);  // 0x0 주소에서 읽기 (Humidity)

        // 온도 데이터 읽기 요청
        PWDATA = 1;
        APB_Write(4'h4, 32'd1);  // 0x4 주소에 1을 써서 Temperature로 전환
        APB_Read(4'h0);          // 다시 0x0 읽어서 온도 읽기

        #1000;
        $finish;
    end

    // APB 읽기 프로토콜
    task APB_Read(input [3:0] addr);
        begin
            @(posedge PCLK);
            PADDR <= addr;
            PWRITE <= 0;
            PSEL <= 1;
            PENABLE <= 1;
            @(posedge PCLK);
            wait (PREADY);
            $display("[%0t] APB READ: ADDR=0x%0h DATA=0x%0h", $time, addr, PRDATA);
            PSEL <= 0;
            PENABLE <= 0;
        end
    endtask

    // APB 쓰기 프로토콜
    task APB_Write(input [3:0] addr, input [31:0] data);
        begin
            @(posedge PCLK);
            PADDR <= addr;
            PWDATA <= data;
            PWRITE <= 1;
            PSEL <= 1;
            PENABLE <= 1;
            @(posedge PCLK);
            wait (PREADY);
            $display("[%0t] APB WRITE: ADDR=0x%0h DATA=0x%0h", $time, addr, data);
            PSEL <= 0;
            PENABLE <= 0;
            PWRITE <= 0;
        end
    endtask

    /////////////////////////////////////////
    // DHT11 간단 모델 (Humidity 55.5%, Temperature 24.3도 가정)
    /////////////////////////////////////////
    initial begin
        forever begin
            wait(dht_io_drv_en == 0 && dht_io == 0); // MCU가 Start 신호 보낼 때까지 기다림
            #20000; // MCU Start Low 유지 시간 (18ms 정도)

            // MCU가 High로 풀었는지 기다림
            wait(dht_io == 1);
            #40; // MCU가 High 유지할 시간 약간 기다림

            // DHT11이 응답 시작
            dht_io_drv_en = 1;
            dht_io_drv = 0; #80; // DHT11 Pull Low 80us
            dht_io_drv = 1; #80; // DHT11 Pull High 80us

            #1000
            // 습도(55.5%) + 온도(24.3도) + Checksum 전송
            send_byte(8'd55); // Humidity Int Part
            send_byte(8'd5);  // Humidity Dec Part
            send_byte(8'd24); // Temperature Int Part
            send_byte(8'd3);  // Temperature Dec Part
            send_byte(8'd87); // Checksum

            dht_io_drv_en = 0;
        end
    end

    task send_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                // Start of bit
                dht_io_drv = 0; #50;  // 50us Low pulse
                dht_io_drv = 1;
                if (data[i])
                    #70;   // Logic 1 (70us High)
                else
                    #26;   // Logic 0 (26us High)
            end
        end
    endtask

endmodule
