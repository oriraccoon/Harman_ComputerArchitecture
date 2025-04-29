`timescale 1ns / 1ps

module PWM(
    input logic clk,
    input logic reset,
    input logic [$clog2(400)-1:0] distance,
    output logic motor_sig
    );

    parameter SYS_CLK = 100_000_000, PWM_CLK = 1_000, DUTY_MAX = 255, STOP = 128;

    logic [7:0] duty_rate;
    logic [7:0] pwm_rate;
    logic o_clk;

    assign duty_rate = distance >= DUTY_MAX ? DUTY_MAX : distance;
    assign pwm_rate = distance / 3;

    clock_divider #(
        .FCOUNT(SYS_CLK/PWM_CLK)
    ) U_1khz (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(o_clk)
    );

    always_comb begin
        if (pwm_rate == 0) begin
            motor_sig = 0;
        end
    end


endmodule
