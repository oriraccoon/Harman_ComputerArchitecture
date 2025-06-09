`timescale 1ns / 1ps


module QVGA_MemController (
    input  logic [ 9:0] x_coor,
    input  logic [ 8:0] y_coor,
    input  logic        display_en,
    input  logic        VGA_SIZE,
    output logic        de,
    output logic [16:0] rAddr,
    input  logic [11:0] rData,
    output logic [ 3:0] vgaRed,
    output logic [ 3:0] vgaGreen,
    output logic [ 3:0] vgaBlue
);

    logic qvga_en;

    assign qvga_en = (VGA_SIZE == 1) ? (x_coor < 640 && y_coor < 480) : (x_coor < 320 && y_coor < 240);
    assign de = qvga_en;

    assign rAddr = qvga_en ? ((VGA_SIZE == 1) ? ((y_coor>>1) * 320 + (x_coor >> 1)) : ((y_coor >> 0) * 320 + (x_coor >> 0))) : 0;
    assign {vgaRed, vgaGreen, vgaBlue} = qvga_en ?
            {rData[11:8], rData[7:4], rData[3:0]} : 0;


endmodule
