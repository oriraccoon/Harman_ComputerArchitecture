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
    input  logic clk,
    input  logic reset,
    input logic [2:0] sw,
    output logic buzzer_pulse
);

    parameter SYS_CLK = 100_000_000;


    logic o_clk;
    logic [$clog2(349)-1:0] FCOUNT;
    logic [$clog2(349)-1:0] count;

    mux_um um_sel(
        .sw(sw[1:0]),
        .val(FCOUNT)
    );
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            o_clk <= 0;
        end else begin
            if (count == FCOUNT - 1) begin
                o_clk <= 1;
                count <= 0;
            end else begin
                count <= count + 1;
                o_clk <= 0;
            end
        end
    end


endmodule

module mux_um (
    input logic [1:0] sw,
    output logic [$clog2(349)-1:0] val
);
    
    parameter DO = 261, RE = 294, MI = 330, FA = 349;

    always_comb begin
        val = 0;
        case (sw)
            2'b00:val = DO;
            2'b01:val = RE;
            2'b10:val = MI;
            2'b11:val = FA;
        endcase
    end


endmodule