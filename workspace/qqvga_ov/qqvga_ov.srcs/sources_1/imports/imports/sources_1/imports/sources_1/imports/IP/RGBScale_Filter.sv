`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/29 16:46:18
// Design Name: 
// Module Name: RGBScale_Filter
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


module RGBScale_Filter(
    input logic [11:0] i_data,
    output logic [11:0] ro_data,
    output logic [11:0] go_data,
    output logic [11:0] bo_data
);

    always_comb begin
        ro_data = {i_data[11:8], 8'b0};
        go_data = {4'b0, i_data[7:4], 4'b0};
        bo_data = {8'b0, i_data[3:0]};
    end

endmodule
