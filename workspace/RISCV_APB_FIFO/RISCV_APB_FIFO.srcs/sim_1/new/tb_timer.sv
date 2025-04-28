`timescale 1ns / 1ps

module tb_timer ();

    // global signal
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;

    Timer_Periph dut(.*);

    // Clock Generation
    always #5 PCLK = ~PCLK;

    // Task: APB Write
    task apb_write(input [3:0] addr, input [31:0] data);
    begin
        @(posedge PCLK);
        PADDR  <= addr;
        PWDATA <= data;
        PWRITE <= 1;
        PENABLE <= 0;
        PSEL   <= 1;

        @(posedge PCLK);
        PENABLE <= 1;

        wait(PREADY);
        @(posedge PCLK);
        PSEL <= 0;
        PENABLE <= 0;
        PWRITE <= 0;
    end
    endtask

    // Task: APB Read
    task apb_read(input [3:0] addr);
    begin
        @(posedge PCLK);
        PADDR  <= addr;
        PWRITE <= 0;
        PENABLE <= 0;
        PSEL   <= 1;

        @(posedge PCLK);
        PENABLE <= 1;

        wait(PREADY);
        @(posedge PCLK);
        PSEL <= 0;
        PENABLE <= 0;
    end
    endtask

    initial begin
        // 초기화
        PCLK = 0; PRESET = 1;
        PADDR = 0;
        PWDATA = 0;
        PWRITE = 0;
        PENABLE = 0;
        PSEL = 0;

        #20;
        PRESET = 0;
        #20;

        // 1. 타이머 설정
        // tcr: 타이머 동작 설정 (tcr[0]=1: enable)
        apb_write(4'h4, 32'h1); // slv_reg1 -> tcr: enable

        // psc: 프리스케일러 값 설정 (클럭 분주)
        apb_write(4'h8, 32'd9); // slv_reg2 -> psc: 9로 설정 (PCLK을 10으로 나눔)

        // arr: 자동 리로드 레지스터 설정
        apb_write(4'hC, 32'd5); // slv_reg3 -> arr: 5로 설정

        // 2. 타이머 동작 관찰
        repeat (20) begin
            apb_read(4'h0); // slv_reg0 -> tcnr 읽기
            @(posedge PCLK);
            $display("[%0t ns] tcnr = %0d", $time, PRDATA);
        end

        // 3. 테스트 종료
        $stop;
    end

endmodule
