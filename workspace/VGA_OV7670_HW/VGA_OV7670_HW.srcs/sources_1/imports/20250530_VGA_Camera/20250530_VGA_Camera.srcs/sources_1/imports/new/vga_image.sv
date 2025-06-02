`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/29 11:31:55
// Design Name: 
// Module Name: vga_image
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

module Filter_mux (
    input  logic [ 2:0] sel,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    input  logic [11:0] x2,
    input  logic [11:0] x3,
    input  logic [11:0] x4,
    output logic [11:0] y
);

    always_comb begin
        y = 12'b0;
        case (sel)
            3'd0: y = x0;
            3'd1: y = x1;
            3'd2: y = x2;
            3'd3: y = x3;
            3'd4: y = x4;
        endcase
    end
endmodule
