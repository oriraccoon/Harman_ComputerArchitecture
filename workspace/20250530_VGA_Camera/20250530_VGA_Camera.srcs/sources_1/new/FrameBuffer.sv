`timescale 1ns / 1ps


module FrameBuffer (
    input  logic        PCLK,
    input  logic [16:0] waddr,
    input  logic [15:0] wdata,
    input  logic        wen,

    input logic rclk,
    input logic oe,
    input  logic [16:0] raddr,
    output logic [15:0] rdata
);

    logic [15:0] ram [0:320*240-1];

    always_ff @(posedge PCLK) begin
        if (wen) begin
            ram[waddr] <= wdata;
        end
    end

    always_ff @( posedge rclk ) begin : read_side
        if (oe) begin
            rdata = ram[raddr];
        end
    end

endmodule
