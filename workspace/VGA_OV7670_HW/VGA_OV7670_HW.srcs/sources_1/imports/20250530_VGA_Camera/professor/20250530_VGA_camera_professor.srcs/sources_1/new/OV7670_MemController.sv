`timescale 1ns / 1ps


module OV7670_MemController (
    input logic pclk,
    input logic reset,
    input logic href,
    input logic vsync,
    input logic [7:0] ov7670_data,
    output logic we,
    output logic [16:0] wAddr,
    output logic [15:0] wData
);

    logic [ 9:0] h_counter;  // 320 * 2 == 640(320 pixel)
    logic [ 7:0] v_counter;  // 240 lines
    logic [15:0] pixel_data;

    assign wAddr = 320 * v_counter + (h_counter >> 1);
    assign wData = pixel_data;

    always_ff @(posedge pclk or posedge reset) begin : h_sequence
        if (reset) begin
            pixel_data <= 0;
            h_counter  <= 0;
            we         <= 1'b0;
        end else begin
            if (href == 1'b0) begin
                h_counter <= 0;
                we        <= 0;
            end else begin
                h_counter <= h_counter + 1;
                if (h_counter[0] == 1'b0) begin  // even data
                    pixel_data[15:8] <= ov7670_data;
                    we               <= 1'b0;
                end else begin  // odd data
                    pixel_data[7:0] <= ov7670_data;
                    we              <= 1'b1;
                end
            end
        end
    end

    always_ff @( posedge pclk, posedge reset ) begin : v_sequence
        if (reset) begin
            v_counter <= 0;
        end
        else begin
            if (vsync == 1'b1) begin
                v_counter <= 0;
            end
            else begin
                if (h_counter == 640 - 1) begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end



endmodule

module Mem_Controller (
    input  logic        PCLK,
    input  logic        reset,
    input  logic        HREF,
    input  logic        VSYNC,
    input  logic [ 7:0] i_data,
    output logic [15:0] wdata,
    output logic        wen,
    output logic [16:0] waddr
);


    logic       FCLK;
    logic [9:0] h_coor;  // QVGA
    logic [8:0] v_coor;  // QVGA
    logic [7:0] first_byte;
    logic [7:0] second_byte;

    assign wdata = {first_byte, second_byte};

    always_ff @( negedge wen or posedge reset ) begin : waddr_merge
        if (reset) begin
            waddr <= 0;
        end
        else begin
            waddr = 320 * v_coor + h_coor;
        end
    end

    always_ff @(posedge PCLK or posedge reset) begin : setting
        if (reset) begin
            FCLK <= 0;
            wen <= 0;
        end else begin
            if ((VSYNC == 0) && (HREF == 1)) begin
                FCLK <= ~FCLK;
            end else begin
                FCLK <= 0;
            end
            wen <= FCLK;
        end
    end


    always_ff @(posedge FCLK or posedge reset) begin : first_byte_read
        if (reset) begin
            first_byte <= 0;
        end else begin
            first_byte <= i_data;
        end
    end

    always_ff @(negedge FCLK or posedge reset) begin : second_byte_read
        if (reset) begin
            second_byte <= 0;
            h_coor <= 0;
        end else begin
            second_byte <= i_data;
            if (h_coor == 320 - 1) begin
                h_coor <= 0;
            end else begin
                h_coor <= h_coor + 1;
            end
        end
    end

    always_ff @(negedge HREF or posedge reset or posedge VSYNC) begin
        if (reset) begin
            v_coor <= 0;
        end else begin
            if (VSYNC) begin
                v_coor = 0;
            end else v_coor = v_coor + 1;
        end
    end

endmodule
