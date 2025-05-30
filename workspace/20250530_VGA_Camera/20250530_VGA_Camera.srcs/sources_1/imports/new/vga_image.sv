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


module vga_image (
    input  logic       clk,
    input  logic       reset,
    input  logic [4:0] c_sw,
    input  logic [2:0] rgb_sw,
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    logic [9:0] x_coor;
    logic [8:0] y_coor;
    logic       display_en;
    logic       pixel_clk;

    logic [15:0] RGB565_data;
    logic [11:0] G_RGB444_data;
    logic [11:0] C_RGB444_data;
    logic [11:0] O_RGB444_data;
    logic [11:0] RED_RGB444_data;
    logic [11:0] GREEN_RGB444_data;
    logic [11:0] BLUE_RGB444_data;

    always_comb begin
        {vgaRed, vgaGreen, vgaBlue} = O_RGB444_data;
    end


    vga_Controller U_VGA_CONTROLLER (.*);

    image_processing U_IMAGE_PROCESS (
        .*,
        .clk(pixel_clk),
        .image_data(RGB565_data),
        .vgaRed(C_RGB444_data[11:8]),
        .vgaGreen(C_RGB444_data[7:4]),
        .vgaBlue(C_RGB444_data[3:0])
    );

    GrayScale_Filter U_GS_F (
        .data(RGB565_data),
        .RGBdata(G_RGB444_data)
    );

    RGBScale_Filter U_RGB_F (
        .i_data(RGB565_data),
        .ro_data(RED_RGB444_data),
        .go_data(GREEN_RGB444_data),
        .bo_data(BLUE_RGB444_data)
    );

    Filter_mux U_F_mux (
        .sel(rgb_sw),
        .x0(C_RGB444_data),
        .x1(G_RGB444_data),
        .x2(RED_RGB444_data),
        .x3(GREEN_RGB444_data),
        .x4(BLUE_RGB444_data),
        .y(O_RGB444_data)
    );


endmodule

module Filter_mux (
    input logic [2:0] sel,
    input logic [11:0] x0,
    input logic [11:0] x1,
    input logic [11:0] x2,
    input logic [11:0] x3,
    input logic [11:0] x4,
    output logic [11:0] y
);
    
    always_comb begin
        case (sel)
            3'd0: y = x0;
            3'd1: y = x1;
            3'd2: y = x2;
            3'd3: y = x3;
            3'd4: y = x4;
        endcase
    end
endmodule
