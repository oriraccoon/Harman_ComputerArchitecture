`timescale 1ns / 1ps

module PWM (
    input logic clk,
    input logic reset,
    input logic [7:0] duty_rate,
    output logic led
);

    parameter SYS_CLK = 100_000_000, PWM_FREQ = 1000, PWM_COUNTER_MAX = 255;

    logic c_clk;

    clock_divider_pwm #(
        .FCOUNT(SYS_CLK / PWM_FREQ)
    ) U_divider (
        .clk  (clk),
        .rst  (reset),
        .o_clk(c_clk)
    );

    logic [7:0] counter;

    always_ff @(posedge c_clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end

    always_comb begin
        if (duty_rate == 0) begin
            led = 1;
        end
        else if (counter < duty_rate) begin
            led = 1;
        end
        else begin
            led = 0;
        end
    end

endmodule


module clock_divider_pwm #(
    parameter FCOUNT = 100_000
)(
    input logic clk,
    input logic rst,
    output logic o_clk
);
    logic [$clog2(FCOUNT/2)-1:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            o_clk <= 0;
        end
        else begin
            if (count == FCOUNT/2 - 1) begin
                o_clk <= ~o_clk;
                count <= 0;
            end
            else begin
                count <= count + 1;
            end
        end
    end
endmodule

