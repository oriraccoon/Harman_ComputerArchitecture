`timescale 1ns/1ps

module tb_Ultrasonic_IP;

    logic PCLK;
    logic PRESET;
    logic echo;
    logic [$clog2(400)-1:0] idr;
    logic trig;

    // DUT �ν��Ͻ�
    Ultrasonic_IP dut (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .echo(echo),
        .idr(idr),
        .trig(trig)
    );

    // PCLK ����: 10ns �ֱ� (100MHz)
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    initial begin
        // �ʱ�ȭ
        PRESET = 1;
        echo = 0;
        #20;
        PRESET = 0;

        // o_PCLK���κ��� trig �߻����� ��ٸ�
        wait(trig == 1);
        $display("[INFO] trig asserted at time %t", $time);

        // trig ����
        wait(trig == 0);
        $display("[INFO] trig deasserted at time %t", $time);

        // echo rising edge
        #500;  // �ణ�� ������ �� echo HIGH (������ �ݻ��)
        echo = 1;
        $display("[TEST] echo HIGH at time %t", $time);

        // ���� �ð� ���� (��: 1740ns = 30cm �Ÿ� ���� 100MHz���� �� 174 cycles)
        #1740;
        echo = 0;
        $display("[TEST] echo LOW at time %t", $time);

        // �Ÿ� ��� ��� ���
        #1000;
        $display("[RESULT] Measured distance (idr): %d cm", idr);

        // �ùķ��̼� ����
        #500;
        $finish;
    end

endmodule
