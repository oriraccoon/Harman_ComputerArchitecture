`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/09 10:52:02
// Design Name: 
// Module Name: Sharpness_Filter
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


module Sharpness_Filter(
    input logic [11:0] BASE_RGB444_data,
    input logic [11:0] FILTERED_RGB444_data,
    output logic [11:0] SHARPNESS_RGB444_data
);

    always_comb begin
        SHARPNESS_RGB444_data[11:8] = ((BASE_RGB444_data[11:8] + FILTERED_RGB444_data[11:8]) >= 4'hF) ? 4'hF : (BASE_RGB444_data[11:8] + FILTERED_RGB444_data[11:8]);
        SHARPNESS_RGB444_data[7:4] = ((BASE_RGB444_data[7:4] + FILTERED_RGB444_data[7:4]) >= 4'hF) ? 4'hF : (BASE_RGB444_data[7:4] + FILTERED_RGB444_data[7:4]);
        SHARPNESS_RGB444_data[3:0] = ((BASE_RGB444_data[3:0] + FILTERED_RGB444_data[3:0]) >= 4'hF) ? 4'hF : (BASE_RGB444_data[3:0] + FILTERED_RGB444_data[3:0]);
    end

endmodule
