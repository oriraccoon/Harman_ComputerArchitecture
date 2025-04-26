`timescale 1ns / 1ps

module PWM(
    input clk,
    input reset,
    input logic [7:0] duty_rate,
    output logic led
    );

    parameter SYS_CLK = 100_000_000, CUSTOM_CLK = 100;
    logic c_clk;
    clock_divider #(
        .FCOUNT(duty_rate * 1_000_000)
    ) U_1khz (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(o_clk)
    );


endmodule

module clock_divider #(
    parameter FCOUNT = 100_000_000
) (
    input  clk,
    input  rst,
    output o_clk
);

    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin  // 1Hz
                r_counter <= 0;
                r_clk <= 1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end
endmodule
