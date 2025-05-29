`timescale 1ns / 1ps

// 영상 처리 모듈, 여기서는 sw에 맞는 rbg값 내보내기
module vgd_switch_rgb_display (
    input  logic [3:0] r_sw,
    input  logic [3:0] g_sw,
    input  logic [3:0] b_sw,
    input  logic       display_en,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    always_comb begin
        if (display_en) begin
            vgaRed   = r_sw;
            vgaGreen = g_sw;
            vgaBlue  = b_sw;
        end else begin
            vgaRed   = 4'b0;
            vgaGreen = 4'b0;
            vgaBlue  = 4'b0;
        end
    end

endmodule

// 위에서 만든 기능에다가 화면 조정 추가
module test_pattern_display (
    input  logic [3:0] control_sw,
    input  logic [3:0] r_sw,
    input  logic [3:0] g_sw,
    input  logic [3:0] b_sw,
    input  logic       display_en,
    input  logic [9:0] x_coor,
    input  logic [8:0] y_coor,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    localparam WHITE_X_COOR = 91, YELLOW_X_COOR = 182, CYAN_X_COOR = 273, GREEN_X_COOR = 364, MAGENTA_X_COOR = 455, RED_X_COOR = 546, BLUE_X_COOR = 640;
    localparam FIRST_Y_COOR = 320, SECOND_Y_COOR = 360, THIRD_Y_COOR = 480;
    localparam LAST1_X_COOR = 111, LAST2_X_COOR = 222, LAST3_X_COOR = 333, LAST4_X_COOR = 455, LAST5_X_COOR = 485, LAST6_X_COOR = 515, LAST7_X_COOR = 546, LAST8_X_COOR = 640;

    logic [3:0] red1, red2, red3, green1, green2, green3, blue1, blue2, blue3;


    always_comb begin
        if (~display_en) begin
            vgaRed   = 4'b0;
            vgaGreen = 4'b0;
            vgaBlue  = 4'b0;
        end
        case (control_sw)
            4'b1000: begin
                if (display_en) begin
                    vgaRed   = r_sw;
                    vgaGreen = g_sw;
                    vgaBlue  = b_sw;
                end else begin
                    vgaRed   = 4'b0;
                    vgaGreen = 4'b0;
                    vgaBlue  = 4'b0;
                end
            end
            4'b0100: begin
                if (
                    ( (x_coor - 215)*(x_coor - 215) + (y_coor - 170)*(y_coor - 170) <= (105**2) ) ||

                    ( (x_coor - 415)*(x_coor - 415) + (y_coor - 170)*(y_coor - 170) <= (105**2) ) ||

                    ( (y_coor >= 170) && (y_coor <= 480) &&
                    (x_coor >= (110 + ((y_coor - 170)*5)/3)) &&
                    (x_coor <= (520 - ((y_coor - 170)*5)/3))
                    )
                ) begin
                    vgaRed   = 4'd15;
                    vgaGreen = 4'd0;
                    vgaBlue  = 4'd0;
                end else begin
                    vgaRed   = 4'd0;
                    vgaGreen = 4'd0;
                    vgaBlue  = 4'd0;
                end

            end
            4'b0001: begin
                if ((x_coor < 320) && (y_coor < -x_coor + 480)) begin
                    if (display_en) begin
                        red1   = r_sw;
                        green1 = g_sw;
                        blue1  = b_sw;
                        vgaRed = red1;
                        vgaGreen = green1;
                        vgaBlue = blue1;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
                else if (~((x_coor < 320) && (y_coor < -x_coor + 480)) || ~((x_coor >= 320) && (y_coor < x_coor + 480))) begin
                    if (display_en) begin
                        vgaRed = red3;
                        vgaGreen = green3;
                        vgaBlue = blue3;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
                else if ((x_coor >= 320) && (y_coor < x_coor + 480)) begin
                    if (display_en) begin
                        vgaRed = red2;
                        vgaGreen = green2;
                        vgaBlue = blue2;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
            end
            4'b0010: begin
                if ((x_coor >= 320) && (y_coor < x_coor + 480)) begin
                    if (display_en) begin
                        red2   = r_sw;
                        green2 = g_sw;
                        blue2  = b_sw;
                        vgaRed = red2;
                        vgaGreen = green2;
                        vgaBlue = blue2;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
                else if ((x_coor < 320) && (y_coor < -x_coor + 480)) begin
                    if (display_en) begin
                        vgaRed = red1;
                        vgaGreen = green1;
                        vgaBlue = blue1;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
                else if (~((x_coor < 320) && (y_coor < -x_coor + 480)) || ~((x_coor >= 320) && (y_coor < x_coor + 480))) begin
                    if (display_en) begin
                        vgaRed = red3;
                        vgaGreen = green3;
                        vgaBlue = blue3;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
            end
            4'b0011: begin
                if (~((x_coor < 320) && (y_coor < -x_coor + 480)) || ~((x_coor >= 320) && (y_coor < x_coor + 480))) begin
                    if (display_en) begin
                        red3   = r_sw;
                        green3 = g_sw;
                        blue3  = b_sw;
                        vgaRed = red3;
                        vgaGreen = green3;
                        vgaBlue = blue3;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
                else if ((x_coor >= 320) && (y_coor < x_coor + 480)) begin
                    if (display_en) begin
                        vgaRed = red2;
                        vgaGreen = green2;
                        vgaBlue = blue2;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
                else if ((x_coor < 320) && (y_coor < -x_coor + 480)) begin
                    if (display_en) begin
                        vgaRed = red1;
                        vgaGreen = green1;
                        vgaBlue = blue1;
                    end else begin
                        vgaRed   = 4'b0;
                        vgaGreen = 4'b0;
                        vgaBlue  = 4'b0;
                    end
                end
            end
            default: begin
                if (display_en) begin
                    // 첫 번째 7가지 색상
                    if ((x_coor < WHITE_X_COOR) && (y_coor < FIRST_Y_COOR)) begin
                        vgaRed   = 4'd15;
                        vgaGreen = 4'd15;
                        vgaBlue  = 4'd15;
                    end
                    else if ( (x_coor >= WHITE_X_COOR) && (x_coor < YELLOW_X_COOR) && (y_coor < FIRST_Y_COOR) ) begin
                        vgaRed   = 4'd15;
                        vgaGreen = 4'd15;
                        vgaBlue  = 4'd0;
                    end
                    else if ( (x_coor >= YELLOW_X_COOR) && (x_coor < CYAN_X_COOR) && (y_coor < FIRST_Y_COOR) ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd15;
                        vgaBlue  = 4'd15;
                    end
                    else if ( (x_coor >= CYAN_X_COOR) && (x_coor < GREEN_X_COOR) && (y_coor < FIRST_Y_COOR) ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd15;
                        vgaBlue  = 4'd0;
                    end
                    else if ( (x_coor >= GREEN_X_COOR) && (x_coor < MAGENTA_X_COOR) && (y_coor < FIRST_Y_COOR) ) begin
                        vgaRed   = 4'd15;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd15;
                    end
                    else if ( (x_coor >= MAGENTA_X_COOR) && (x_coor < RED_X_COOR) && (y_coor < FIRST_Y_COOR) ) begin
                        vgaRed   = 4'd15;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd0;
                    end
                    else if ( (x_coor >= RED_X_COOR) && (x_coor < BLUE_X_COOR) && (y_coor < FIRST_Y_COOR) ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd15;
                    end  
                    
                    
                    // 두 번째 7가지 색상
                    else if ( (x_coor < WHITE_X_COOR) && (y_coor >= FIRST_Y_COOR) && (y_coor < SECOND_Y_COOR) ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd15;
                    end
                    else if ( (x_coor >= WHITE_X_COOR) && (x_coor < YELLOW_X_COOR) && (y_coor >= FIRST_Y_COOR) && (y_coor < SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd0;
                    end
                    else if ( (x_coor >= YELLOW_X_COOR) && (x_coor < CYAN_X_COOR) && (y_coor >= FIRST_Y_COOR) && (y_coor < SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd15;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd15;
                    end
                    else if ( (x_coor >= CYAN_X_COOR) && (x_coor < GREEN_X_COOR) && (y_coor >= FIRST_Y_COOR) && (y_coor < SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd0;
                    end
                    else if ( (x_coor >= GREEN_X_COOR) && (x_coor < MAGENTA_X_COOR) && (y_coor >= FIRST_Y_COOR) && (y_coor < SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd15;
                        vgaBlue  = 4'd15;
                    end
                    else if ( (x_coor >= MAGENTA_X_COOR) && (x_coor < RED_X_COOR) && (y_coor >= FIRST_Y_COOR) && (y_coor < SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd0;
                    end
                    else if ( (x_coor >= RED_X_COOR) && (x_coor < BLUE_X_COOR) && (y_coor >= FIRST_Y_COOR) && (y_coor < SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd15;
                        vgaGreen = 4'd15;
                        vgaBlue  = 4'd15;
                    end  
                    
                    
                    // 세 번째 8가지 색상
                    else if ( (x_coor < LAST1_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd8;
                    end
                    else if ( (x_coor >= LAST1_X_COOR) && (x_coor < LAST2_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd15;
                        vgaGreen = 4'd15;
                        vgaBlue  = 4'd15;
                    end
                    else if ( (x_coor >= LAST2_X_COOR) && (x_coor < LAST3_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd8;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd8;
                    end
                    else if ( (x_coor >= LAST3_X_COOR) && (x_coor < LAST4_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd0;
                    end


                    else if ( (x_coor >= LAST4_X_COOR) && (x_coor < LAST5_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd1;
                        vgaGreen = 4'd1;
                        vgaBlue  = 4'd1;
                    end
                    else if ( (x_coor >= LAST5_X_COOR) && (x_coor < LAST6_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd3;
                        vgaGreen = 4'd3;
                        vgaBlue  = 4'd3;
                    end
                    else if ( (x_coor >= LAST6_X_COOR) && (x_coor < LAST7_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd6;
                        vgaGreen = 4'd6;
                        vgaBlue  = 4'd6;
                    end
                    else if ( (x_coor >= LAST7_X_COOR) && (x_coor < LAST8_X_COOR) && (y_coor >= SECOND_Y_COOR)  ) begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd0;
                    end else begin
                        vgaRed   = 4'd0;
                        vgaGreen = 4'd0;
                        vgaBlue  = 4'd0;
                    end
                end else begin
                    vgaRed   = 4'b0;
                    vgaGreen = 4'b0;
                    vgaBlue  = 4'b0;
                end
            end
        endcase
    end

endmodule
