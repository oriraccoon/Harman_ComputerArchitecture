`timescale 1ns / 1ps


module vga_Controller (
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] bar_height_hist[0:15],
    output logic       Hsync,
    output logic       Vsync,
    output logic       DE1,
    output logic       DE2,
    output logic       DE3,
    output logic       DE4,
    output logic       DEhorizonLine,
    output logic       DEverticalLine,
    output logic       DEhist0,
    output logic       DEhist1,
    output logic       DEhist2,
    output logic       DEhist3,
    output logic       DEhist4,
    output logic       DEhist5,
    output logic       DEhist6,
    output logic       DEhist7,
    output logic       DEhist8,
    output logic       DEhist9,
    output logic       DEhist10,
    output logic       DEhist11,
    output logic       DEhist12,
    output logic       DEhist13,
    output logic       DEhist14,
    output logic       DEhist15,
    output logic       DEhistFont,
    output logic [9:0] x_coor,
    output logic [9:0] y_coor,
    output logic pixel_clk
);

    logic pclk;
    logic [9:0] h_counter;
    logic [9:0] v_counter;



    clock_div #(
        .FCOUNT(4)
    ) U_PIXEL_CLOCK_GENERATOR (
        .*,
        .o_clk(pixel_clk)
    );

    pix_counter U_pix_counter (
        .pclk     (pixel_clk),
        .reset    (reset),
        .h_counter(h_counter),
        .v_counter(v_counter)
    );

    vga_decoder2 U_vga_decoder (
        .v_counter      (v_counter),
        .h_counter      (h_counter),
        .Hsync         (Hsync),
        .Vsync         (Vsync),
        .x_coor        (x_coor),
        .y_coor        (y_coor),
        .DE1            (DE1),
        .DE2            (DE2),
        .DE3            (DE3),
        .DE4            (DE4),
        .DEhorizonLine  (DEhorizonLine),
        .DEverticalLine (DEverticalLine),
        .DEhist0        (DEhist0),
        .DEhist1        (DEhist1),
        .DEhist2        (DEhist2),
        .DEhist3        (DEhist3),
        .DEhist4        (DEhist4),
        .DEhist5        (DEhist5),
        .DEhist6        (DEhist6),
        .DEhist7        (DEhist7),
        .DEhist8        (DEhist8),
        .DEhist9        (DEhist9),
        .DEhist10       (DEhist10),
        .DEhist11       (DEhist11),
        .DEhist12       (DEhist12),
        .DEhist13       (DEhist13),
        .DEhist14       (DEhist14),
        .DEhist15       (DEhist15),
        .DEhistFont     (DEhistFont),
        .bar_height_hist(bar_height_hist)
    );

endmodule


//25mHz clock generator
module pixel_clk_gen (
    input  logic clk,
    input  logic reset,
    output logic pclk
);

    logic [1:0] p_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            p_counter <= 0;
            pclk      <= 1'b0;
        end else begin
            if (p_counter == 3) begin
                p_counter <= 0;
                pclk      <= 1'b1;
            end else begin
                p_counter <= p_counter + 1;
                pclk      <= 1'b0;
            end
        end
    end
endmodule

// HV 픽셀카운터
module pix_counter (
    input  logic       pclk,
    input  logic       reset,
    output logic [9:0] h_counter,
    output logic [9:0] v_counter
);

    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge pclk, posedge reset) begin : Horizontal_Counter
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin : Vertical_Counter
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end
endmodule

//sync 생성, DE 및 x y 출력
module vga_decoder2 (
    input  logic [9:0] v_counter,             //800
    input  logic [9:0] h_counter,             //525
    output logic       Hsync,
    output logic       Vsync,
    output logic [9:0] x_coor,               //640
    output logic [9:0] y_coor,               //480
    output logic       DE1,
    output logic       DE2,
    output logic       DE3,
    output logic       DE4,
    output logic       DEhorizonLine,
    output logic       DEverticalLine,
    output logic       DEhist0,
    output logic       DEhist1,
    output logic       DEhist2,
    output logic       DEhist3,
    output logic       DEhist4,
    output logic       DEhist5,
    output logic       DEhist6,
    output logic       DEhist7,
    output logic       DEhist8,
    output logic       DEhist9,
    output logic       DEhist10,
    output logic       DEhist11,
    output logic       DEhist12,
    output logic       DEhist13,
    output logic       DEhist14,
    output logic       DEhist15,
    output logic       DEhistFont,
    input  logic [7:0] bar_height_hist[0:15]
);
    //horizon 정보
    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam HSync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;

    //vertical 정보
    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam VSync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_frame = 525;

    assign Hsync         = !((h_counter >= (H_Visible_area + H_Front_porch))  //sync의 시작 -> 0으로 내림
 && (h_counter < (H_Visible_area + H_Front_porch + HSync_pulse)));  //sync의 끝   -> 1로 복귀

    assign Vsync         = !((v_counter >= (V_Visible_area + V_Front_porch))  //sync의 시작 -> 0으로 내림
 && (v_counter < (V_Visible_area + V_Front_porch + VSync_pulse)));  //sync의 끝   -> 1로 복귀

    assign DE1            = (h_counter >= 0 && h_counter < 320) && (v_counter >= 0 && v_counter < 240);
    assign DE2            = (h_counter >= 0 && h_counter < 320) && (v_counter >= 240 && v_counter < 480);
    assign DE3            = (h_counter >= 320 && h_counter < 640) && (v_counter >= 0 && v_counter < 240);
    assign DE4            = (h_counter >= 320 && h_counter < 640) && (v_counter >= 240 && v_counter < 480);

    //히스토그램 송출용 DE
    assign DEverticalLine = (h_counter >= 30 && h_counter < 35) && (v_counter >= 250 && v_counter < 470);  //세로선 ㅣ
    assign DEhorizonLine  = (h_counter >= 10 && h_counter < 310) && (v_counter >= 450 && v_counter < 455); //가로선 ㅡ

    assign DEhist0  = (h_counter >= 40  && h_counter < 50)   && (v_counter >= 455 - bar_height_hist[0]  && v_counter < 455);
    assign DEhist1  = (h_counter >= 55  && h_counter < 65)   && (v_counter >= 455 - bar_height_hist[1]  && v_counter < 455);
    assign DEhist2  = (h_counter >= 70  && h_counter < 80)   && (v_counter >= 455 - bar_height_hist[2]  && v_counter < 455);
    assign DEhist3  = (h_counter >= 85  && h_counter < 95)   && (v_counter >= 455 - bar_height_hist[3]  && v_counter < 455);
    assign DEhist4  = (h_counter >= 100 && h_counter < 110)  && (v_counter >= 455 - bar_height_hist[4]  && v_counter < 455);
    assign DEhist5  = (h_counter >= 115 && h_counter < 125)  && (v_counter >= 455 - bar_height_hist[5]  && v_counter < 455);
    assign DEhist6  = (h_counter >= 130 && h_counter < 140)  && (v_counter >= 455 - bar_height_hist[6]  && v_counter < 455);
    assign DEhist7  = (h_counter >= 145 && h_counter < 155)  && (v_counter >= 455 - bar_height_hist[7]  && v_counter < 455);
    assign DEhist8  = (h_counter >= 160 && h_counter < 170)  && (v_counter >= 455 - bar_height_hist[8]  && v_counter < 455);
    assign DEhist9  = (h_counter >= 175 && h_counter < 185)  && (v_counter >= 455 - bar_height_hist[9]  && v_counter < 455);
    assign DEhist10 = (h_counter >= 190 && h_counter < 200)  && (v_counter >= 455 - bar_height_hist[10] && v_counter < 455);
    assign DEhist11 = (h_counter >= 205 && h_counter < 215)  && (v_counter >= 455 - bar_height_hist[11] && v_counter < 455);
    assign DEhist12 = (h_counter >= 220 && h_counter < 230)  && (v_counter >= 455 - bar_height_hist[12] && v_counter < 455);
    assign DEhist13 = (h_counter >= 235 && h_counter < 245)  && (v_counter >= 455 - bar_height_hist[13] && v_counter < 455);
    assign DEhist14 = (h_counter >= 250 && h_counter < 260)  && (v_counter >= 455 - bar_height_hist[14] && v_counter < 455);
    assign DEhist15 = (h_counter >= 265 && h_counter < 275)  && (v_counter >= 455 - bar_height_hist[15] && v_counter < 455);

    assign DEhistFont = (h_counter >= 35 && h_counter < 285) && (v_counter >= 460 && v_counter < 480); 

    assign x_coor        = h_counter;
    assign y_coor        = v_counter;
endmodule

module clock_div #(
    parameter FCOUNT = 4
) (
    input  logic clk,
    input  logic reset,
    output logic o_clk
);

    logic [31:0] counter;

    always_ff @(posedge clk or posedge reset) begin : Pixel_clock_generator
        if (reset) begin
            counter <= 0;
            o_clk   <= 0;
        end else begin
            // if (counter == (FCOUNT / 2) - 1) begin
            if (counter == FCOUNT - 1) begin
                // o_clk <= ~o_clk;
                o_clk   <= 1;
                counter <= 0;
            end else begin
                o_clk   <= 0;
                counter <= counter + 1;
            end
        end
    end
endmodule