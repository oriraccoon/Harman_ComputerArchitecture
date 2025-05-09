`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/08 16:30:11
// Design Name: 
// Module Name: buzzer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module buzzer (
    input logic clk,
    input logic reset,
    input logic [2:0] sw,
    output logic buzzer_pulse
);

    parameter SYS_CLK = 100_000_000;


    logic o_clk;
    logic [$clog2(349)-1:0] FCOUNT;
    logic [$clog2(100_000_000)-1:0] count;

    mux_um um_sel (
        .*,
        .switch(sw[2]),
        .val(FCOUNT)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            o_clk <= 0;
        end else begin
            if (count == (SYS_CLK / (FCOUNT * 2)) - 1) begin
                o_clk <= ~o_clk;
                count <= 0;
            end else begin
                count <= count + 1;
            end
        end
    end

    always_comb begin
        if (sw[2]) buzzer_pulse = o_clk;
        else buzzer_pulse = 0;
    end


endmodule

module mux_um (
    input logic clk,
    input logic reset,
    input logic switch,
    output logic [$clog2(349)-1:0] val
);

    parameter DO = 261, RE = 294, MI = 330, FA = 349, SOL = 392, LA = 440, SI = 494, DDO = 523;

    logic o_clk;
    logic [$clog2(100_000_000)-1:0] count;
    logic [4:0] sw;


    always_comb begin
        val = 0;
        case (sw)
            5'b00000: val = DO;
            5'b00001: val = MI;
            5'b00010: val = SOL;
            5'b00011: val = DO;
            5'b00100: val = MI;
            5'b00101: val = SOL;
            5'b00110: val = LA;
            5'b00111: val = LA;
            5'b01000: val = LA;
            5'b01001: val = SOL;
            5'b01010: val = SOL;
            5'b01011: val = FA;
            5'b01100: val = FA;
            5'b01101: val = FA;
            5'b01110: val = MI;
            5'b10000: val = MI;
            5'b10001: val = MI;
            5'b10010: val = RE;
            5'b10011: val = RE;
            5'b10100: val = RE;
            5'b10101: val = DO;
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            o_clk <= 0;
        end else begin
            if (count == (100_000_000 / 2) - 1) begin
                o_clk <= 1;
                count <= 0;
            end else begin
                count <= count + 1;
                o_clk <= 0;
            end
        end
    end

    always_ff @(posedge o_clk or posedge reset) begin
        if (reset) begin
            sw <= 0;
        end else begin
            if(!switch) sw <= 0;
            else begin
                sw <= sw + 1;
                if(sw == 5'b10110) sw <= 0;
            end
        end
    end

endmodule

