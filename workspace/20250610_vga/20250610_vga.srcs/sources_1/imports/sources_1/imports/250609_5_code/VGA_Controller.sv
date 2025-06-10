`timescale 1ns / 1ps

module vga_Controller (
    input  logic       clk,
    input  logic       reset,
    output logic       Hsync,
    output logic       Vsync,
    output logic       display_en,
    output logic [9:0] x_coor,
    output logic [8:0] y_coor,
    output logic r_clk,
    output logic       pixel_clk,
    output logic       DE1,
    output logic       DE2,
    output logic       DE3,
    output logic       DE4,

    //2사분면
    input  logic [7:0] bar_height_hist[0:15],
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

    //3사분면
    input  logic [7:0] abar_height_hist[0:15],
    output logic       aDEhorizonLine,
    output logic       aDEverticalLine,
    output logic       aDEhist0,
    output logic       aDEhist1,
    output logic       aDEhist2,
    output logic       aDEhist3,
    output logic       aDEhist4,
    output logic       aDEhist5,
    output logic       aDEhist6,
    output logic       aDEhist7,
    output logic       aDEhist8,
    output logic       aDEhist9,
    output logic       aDEhist10,
    output logic       aDEhist11,
    output logic       aDEhist12,
    output logic       aDEhist13,
    output logic       aDEhist14,
    output logic       aDEhist15,
    output logic       aDEhistFont
);

    logic [9:0] h_counter, v_counter;
    assign r_clk = clk;

    vga_decoder U_vga_decoder (.*);

    pixel_counter_600x480 U_PIXEL_COUNTER_600x400 (.*);

    clock_div #(
        .FCOUNT(4)
    ) U_PIXEL_CLOCK_GENERATOR (
        .*,
        .o_clk(pixel_clk)
    );

endmodule


module vga_decoder (
    input  logic [9:0] h_counter,
    input  logic [9:0] v_counter,
    output logic       display_en,
    output logic [9:0] x_coor,
    output logic [8:0] y_coor,
    output logic       Hsync,
    output logic       Vsync,
    output logic       DE1,
    output logic       DE2,
    output logic       DE3,
    output logic       DE4,
    //2사분면
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
    input  logic [7:0] bar_height_hist[0:15],
    //3사분면
    output logic       aDEhorizonLine,
    output logic       aDEverticalLine,
    output logic       aDEhist0,
    output logic       aDEhist1,
    output logic       aDEhist2,
    output logic       aDEhist3,
    output logic       aDEhist4,
    output logic       aDEhist5,
    output logic       aDEhist6,
    output logic       aDEhist7,
    output logic       aDEhist8,
    output logic       aDEhist9,
    output logic       aDEhist10,
    output logic       aDEhist11,
    output logic       aDEhist12,
    output logic       aDEhist13,
    output logic       aDEhist14,
    output logic       aDEhist15,
    output logic       aDEhistFont,
    input  logic [7:0] abar_height_hist[0:15]
);
    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam HSync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;

    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam VSync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_frame = 525;

    always_comb begin : outport_condition
        Hsync = ~((h_counter >= (H_Visible_area + H_Front_porch)) &&
                 (h_counter < (H_Visible_area + H_Front_porch + HSync_pulse)));

        Vsync = ~((v_counter >= (V_Visible_area + V_Front_porch)) &&
                 (v_counter < (V_Visible_area + V_Front_porch + VSync_pulse)));

        display_en = ((h_counter < H_Visible_area) && (v_counter < V_Visible_area));

        x_coor = h_counter;
        y_coor = v_counter;

        DE1            = (h_counter >= 0 && h_counter < 320) && (v_counter >= 0 && v_counter < 240);
        DE2            = (h_counter >= 0 && h_counter < 320) && (v_counter >= 240 && v_counter < 480);
        DE3            = (h_counter >= 320 && h_counter < 640) && (v_counter >= 0 && v_counter < 240);
        DE4            = (h_counter >= 320 && h_counter < 640) && (v_counter >= 240 && v_counter < 480);

        // 2사분면 히스토그램 작성
        DEverticalLine = (h_counter >= 30 && h_counter < 35) && (v_counter >= 250 && v_counter < 470);  //세로선 ㅣ
        DEhorizonLine  = (h_counter >= 10 && h_counter < 310) && (v_counter >= 450 && v_counter < 455); //가로선 ㅡ
        DEhist0  = (h_counter >= 40  && h_counter < 50)   && (v_counter >= 455 - bar_height_hist[0]  && v_counter < 455);
        DEhist1  = (h_counter >= 55  && h_counter < 65)   && (v_counter >= 455 - bar_height_hist[1]  && v_counter < 455);
        DEhist2  = (h_counter >= 70  && h_counter < 80)   && (v_counter >= 455 - bar_height_hist[2]  && v_counter < 455);
        DEhist3  = (h_counter >= 85  && h_counter < 95)   && (v_counter >= 455 - bar_height_hist[3]  && v_counter < 455);
        DEhist4  = (h_counter >= 100 && h_counter < 110)  && (v_counter >= 455 - bar_height_hist[4]  && v_counter < 455);
        DEhist5  = (h_counter >= 115 && h_counter < 125)  && (v_counter >= 455 - bar_height_hist[5]  && v_counter < 455);
        DEhist6  = (h_counter >= 130 && h_counter < 140)  && (v_counter >= 455 - bar_height_hist[6]  && v_counter < 455);
        DEhist7  = (h_counter >= 145 && h_counter < 155)  && (v_counter >= 455 - bar_height_hist[7]  && v_counter < 455);
        DEhist8  = (h_counter >= 160 && h_counter < 170)  && (v_counter >= 455 - bar_height_hist[8]  && v_counter < 455);
        DEhist9  = (h_counter >= 175 && h_counter < 185)  && (v_counter >= 455 - bar_height_hist[9]  && v_counter < 455);
        DEhist10 = (h_counter >= 190 && h_counter < 200)  && (v_counter >= 455 - bar_height_hist[10] && v_counter < 455);
        DEhist11 = (h_counter >= 205 && h_counter < 215)  && (v_counter >= 455 - bar_height_hist[11] && v_counter < 455);
        DEhist12 = (h_counter >= 220 && h_counter < 230)  && (v_counter >= 455 - bar_height_hist[12] && v_counter < 455);
        DEhist13 = (h_counter >= 235 && h_counter < 245)  && (v_counter >= 455 - bar_height_hist[13] && v_counter < 455);
        DEhist14 = (h_counter >= 250 && h_counter < 260)  && (v_counter >= 455 - bar_height_hist[14] && v_counter < 455);
        DEhist15 = (h_counter >= 265 && h_counter < 275)  && (v_counter >= 455 - bar_height_hist[15] && v_counter < 455);
        DEhistFont = (h_counter >= 35 && h_counter < 285) && (v_counter >= 460 && v_counter < 480); 

        // 3사분면 히스토그램 작성
        aDEverticalLine = (h_counter >= 350 && h_counter < 355) && (v_counter >= 250 && v_counter < 470);  //세로선 ㅣ (30+320, 35+320)
        aDEhorizonLine  = (h_counter >= 330 && h_counter < 630) && (v_counter >= 450 && v_counter < 455); //가로선 ㅡ (10+320, 310+320)
        aDEhist0  = (h_counter >= 360 && h_counter < 370)  && (v_counter >= 455 - abar_height_hist[0]  && v_counter < 455);
        aDEhist1  = (h_counter >= 375 && h_counter < 385)  && (v_counter >= 455 - abar_height_hist[1]  && v_counter < 455);
        aDEhist2  = (h_counter >= 390 && h_counter < 400)  && (v_counter >= 455 - abar_height_hist[2]  && v_counter < 455);
        aDEhist3  = (h_counter >= 405 && h_counter < 415)  && (v_counter >= 455 - abar_height_hist[3]  && v_counter < 455);
        aDEhist4  = (h_counter >= 420 && h_counter < 430)  && (v_counter >= 455 - abar_height_hist[4]  && v_counter < 455);
        aDEhist5  = (h_counter >= 435 && h_counter < 445)  && (v_counter >= 455 - abar_height_hist[5]  && v_counter < 455);
        aDEhist6  = (h_counter >= 450 && h_counter < 460)  && (v_counter >= 455 - abar_height_hist[6]  && v_counter < 455);
        aDEhist7  = (h_counter >= 465 && h_counter < 475)  && (v_counter >= 455 - abar_height_hist[7]  && v_counter < 455);
        aDEhist8  = (h_counter >= 480 && h_counter < 490)  && (v_counter >= 455 - abar_height_hist[8]  && v_counter < 455);
        aDEhist9  = (h_counter >= 495 && h_counter < 505)  && (v_counter >= 455 - abar_height_hist[9]  && v_counter < 455);
        aDEhist10 = (h_counter >= 510 && h_counter < 520)  && (v_counter >= 455 - abar_height_hist[10] && v_counter < 455);
        aDEhist11 = (h_counter >= 525 && h_counter < 535)  && (v_counter >= 455 - abar_height_hist[11] && v_counter < 455);
        aDEhist12 = (h_counter >= 540 && h_counter < 550)  && (v_counter >= 455 - abar_height_hist[12] && v_counter < 455);
        aDEhist13 = (h_counter >= 555 && h_counter < 565)  && (v_counter >= 455 - abar_height_hist[13] && v_counter < 455);
        aDEhist14 = (h_counter >= 570 && h_counter < 580)  && (v_counter >= 455 - abar_height_hist[14] && v_counter < 455);
        aDEhist15 = (h_counter >= 585 && h_counter < 595)  && (v_counter >= 455 - abar_height_hist[15] && v_counter < 455);
        aDEhistFont = (h_counter >= 355 && h_counter < 605) && (v_counter >= 460 && v_counter < 480); // (35+320, 285+320)
    end

endmodule

module pixel_counter_600x480 (
    input  logic       pixel_clk,
    input  logic       reset,
    output logic [9:0] h_counter,
    output logic [9:0] v_counter
);

    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(negedge pixel_clk or posedge reset) begin : Horizontal_counter
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin  // 640을 위해 800 count
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge pixel_clk or posedge reset) begin : Vertical_counter
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin  // 480을 위해 525 count
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end

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
            if (counter == (FCOUNT / 2) - 1) begin
            //if (counter == FCOUNT - 1) begin
                o_clk <= ~o_clk;
                // o_clk   <= 1;
                counter <= 0;
            end else begin
                //o_clk   <= 0;
                counter <= counter + 1;
            end
        end
    end
endmodule
