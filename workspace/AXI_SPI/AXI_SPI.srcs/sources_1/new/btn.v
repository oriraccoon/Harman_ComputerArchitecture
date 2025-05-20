`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/20 15:34:13
// Design Name: 
// Module Name: btn
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


module btn(
    input clk,
    input reset,
    input btn,
    output reg o_btn
    );

    reg sync0, sync1, sync2;
    reg o_btn_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync0 <= 0;
            sync1 <= 0;
            sync2 <= 0;
            o_btn <= 0;
        end
        else begin
            sync2 <= btn;
            sync1 <= sync2;
            sync0 <= sync1;
            o_btn <= o_btn_reg;
        end
    end

    always @(*) begin
        if ((btn == 1) && (sync0 == 1)) begin
            o_btn_reg = 1;
        end
        else if ((btn == 0) && (sync0 == 0)) begin
            o_btn_reg = 0;
        end
        else o_btn_reg = o_btn;
    end

endmodule
