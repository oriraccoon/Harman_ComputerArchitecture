`timescale 1ns/1ps

module tb_Humidity_Periph_only_dht;

    logic        clk;
    logic        rst;
    tri          dht_io;
    logic        dht_drv;
    logic        dht_oe;
    logic [5:0]  bit_count_o;
    logic [2:0]  c_state;

    assign dht_io = dht_oe ? dht_drv : 1'bz;

    // DUT 인스턴스
    Humidity_Periph dut (
        .PCLK(clk),
        .PRESET(rst),
        .dht_io(dht_io),
        .bit_count_o(bit_count_o),
        .c_state(c_state)
        // 나머지 APB 포트는 연결하지 않음
    );
    

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Reset & 센서 시뮬레이션
    initial begin
        rst = 1;
        dht_drv = 1;
        dht_oe = 0;
        #100;
        rst = 0;

        // FSM이 START → WAIT 진입
        wait (dut.U_Humidity.state == dut.U_Humidity.START);
        @(posedge clk);
        wait (dut.U_Humidity.state == dut.U_Humidity.WAIT);
        @(posedge clk);

        #1000; // MCU가 dht_io에서 손 뗐다고 가정
        dht_oe = 1;

        // DHT 응답 시퀀스
        dht_drv = 0; #(80_000); // 80us LOW
        dht_drv = 1; #(80_000); // 80us HIGH

        // 5바이트 데이터 전송
        send_byte(8'd55); // humi_int
        send_byte(8'd0);  // humi_dec
        send_byte(8'd24); // temp_int
        send_byte(8'd0);  // temp_dec
        send_byte(8'd79); // checksum = 55 + 0 + 24 + 0

        dht_drv = 0;
        #(100_000); // 데이터 끝난 후 여유 시간
        @(posedge clk);
        dht_oe = 0;

        #1_000_000; // 관찰 시간 확보 후 시뮬 종료

        $finish;
    end

    // bit 전송: 정확하게 FSM이 포착하도록 1bit당 LOW 50us + HIGH x us
    task send_bit(input bit b);
        begin
            dht_drv = 0; #(50_000); // 50us LOW
            dht_drv = 1;
            if (b) #(70_000);       // 70us HIGH for '1'
            else    #(28_000);      // 28us HIGH for '0'
        end
    endtask

    // byte 전송
    task send_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                send_bit(data[i]);
            end
        end
    endtask

endmodule
