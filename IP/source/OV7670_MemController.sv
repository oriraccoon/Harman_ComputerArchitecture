`timescale 1ns / 1ps

module ov7670_controller (
    input  logic        pclk,
    input  logic        reset,
    input  logic        href,
    input  logic        vsync,
    input  logic [ 7:0] ov7670_data,
    output logic        we,
    output logic [16:0] wAddr,
    output logic [11:0] wData
);

    logic [ 9:0] h_counter;
    logic [ 7:0] v_counter;
    logic [11:0] temp_cam_data;

    assign wAddr = v_counter * 320 + h_counter[9:1];
    assign wData = temp_cam_data;

    always_ff @(posedge pclk, posedge reset) begin
        if (reset) begin
            temp_cam_data <= 0;
            h_counter     <= 0;
            we            <= 1'b0;
        end else begin
            if (href == 1'b0) begin
                h_counter <= 0;
                we        <= 1'b0;
            end else begin
                h_counter <= h_counter + 1;
                if (h_counter[0] == 1'b0) begin  // even pixel data
                    temp_cam_data[11:8] <= ov7670_data[7:4];
                    temp_cam_data[7:5]  <= ov7670_data[2:0];
                    we                  <= 1'b0;
                end else begin
                    temp_cam_data[4]   <= ov7670_data[7];
                    temp_cam_data[3:0] <= ov7670_data[4:1];
                    we                 <= 1'b1;
                end
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (vsync == 1'b0) begin
                if (h_counter == 640 - 1) begin
                    v_counter <= v_counter + 1;
                end
            end else begin
                v_counter <= 0;
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
    output logic [11:0] wdata,
    output logic        wen,
    output logic [16:0] waddr
);


    logic       FCLK;
    logic [9:0] h_coor;  // QVGA
    logic [8:0] v_coor;  // QVGA
    logic [7:0] first_byte;
    logic [7:0] second_byte;

    assign wdata = {first_byte[7:4], first_byte[2:0], second_byte[7], second_byte[4:1]};

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

module OV7670_MemController (
    input  logic        pclk,
    input  logic        reset,
    input  logic        href,
    input  logic        v_sync,
    input  logic [ 7:0] ov7670_data,
    output logic        we,
    output logic [16:0] wAddr,
    output logic [15:0] wData
);

    logic [9:0] h_counter;
    logic [7:0] v_counter;
    logic [7:0] byte0, byte1;
    logic       byte_toggle;
    logic [15:0] pix_data_reg;
    logic [16:0] addr_reg;

    always_ff @(posedge pclk) begin
        if (reset) begin
            h_counter     <= 0;
            v_counter     <= 0;
            byte0         <= 0;
            byte1         <= 0;
            byte_toggle   <= 0;
            we            <= 0;
            pix_data_reg  <= 0;
            addr_reg      <= 0;
        end else begin
            we <= 0;
            if (v_sync) begin
                h_counter   <= 0;
                v_counter   <= 0;
                byte_toggle <= 0;
            end else if (href) begin
                if (byte_toggle == 0) begin
                    byte0 <= ov7670_data;
                end else begin
                    pix_data_reg <= {byte0, ov7670_data};  // safe: ov7670_data는 이미 valid
                    addr_reg     <= (v_counter>>1) * 160 + (h_counter>>1);
                    h_counter    <= h_counter + 1;
                    we    <= 1;
                end
                byte_toggle <= ~byte_toggle;

                if (h_counter == 319 && byte_toggle == 1) begin //319
                    h_counter <= 0;
                    if (v_counter < 239) // 239
                        v_counter <= v_counter + 1;
                end
            end else begin
                h_counter   <= 0;
                byte_toggle <= 0;
            end
        end
    end

    assign wAddr = addr_reg;
    assign wData = pix_data_reg;

endmodule