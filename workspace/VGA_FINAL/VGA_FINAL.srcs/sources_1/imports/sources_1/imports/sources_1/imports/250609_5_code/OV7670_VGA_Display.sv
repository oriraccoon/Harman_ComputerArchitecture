`timescale 1ns / 1ps


module OV7670_VGA_Display (
    // global signals
    input  logic       clk, 
    input  logic       reset,
    input  logic [5:0] rgb_sw,
    input  logic [1:0] btn,
    input  logic [1:0] g_btn,
    input logic gray_sw,
    input logic gamma_sw,
    input logic bright_sw,
    input logic DE1_sw,
    input logic DE3_sw,
    // ov7670 signals
    output logic       ov7670_x_clk,
    input  logic       ov7670_pixel_clk,
    input  logic       ov7670_href,
    input  logic       ov7670_vsync,
    input  logic [7:0] ov7670_data,
    output logic       SCL,
    output logic       SDA,
    // export signals
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    logic [3:0] vgaRed;
    logic [3:0] vgaGreen;
    logic [3:0] vgaBlue;
    logic       display_en;
    logic [9:0] x_coor;
    logic [8:0] y_coor;
    logic       we;
    logic [16:0] wAddr, rAddr;
    logic [11:0] wData;
    logic [11:0] rData;
    logic w_rclk;
    logic rclk;
    logic oe;
    logic soe;
    logic VGA_SIZE;
    logic clk_25;
    logic r_clk;


    logic [11:0] BASE_RGB444_data;
    logic [11:0] O_RGB444_data;
    logic [11:0] GAMMA_RGB444_data;
    logic [11:0] BRIGHT_RGB444_data;
    logic [11:0] CONTRAST_RGB444_data;
    logic [11:0] GRAY_RGB444_data;
    logic [11:0] gray_org_data;
    logic G_down_btn, G_up_btn;
    logic B_down_btn, B_up_btn;
   
    //histogram
    logic       DE1;
    logic       DE2;
    logic       DE3;
    logic       DE4;
    logic       DEhorizonLine;
    logic       DEverticalLine;
    logic       DEhist0;
    logic       DEhist1;
    logic       DEhist2;
    logic       DEhist3;
    logic       DEhist4;
    logic       DEhist5;
    logic       DEhist6;
    logic       DEhist7;
    logic       DEhist8;
    logic       DEhist9;
    logic       DEhist10;
    logic       DEhist11;
    logic       DEhist12;
    logic       DEhist13;
    logic       DEhist14;
    logic       DEhist15;
    logic       DEhistFont;
    logic [7:0] bar_height_hist [0:15];
    logic       aDEhorizonLine;
    logic       aDEverticalLine;
    logic       aDEhist0;
    logic       aDEhist1;
    logic       aDEhist2;
    logic       aDEhist3;
    logic       aDEhist4;
    logic       aDEhist5;
    logic       aDEhist6;
    logic       aDEhist7;
    logic       aDEhist8;
    logic       aDEhist9;
    logic       aDEhist10;
    logic       aDEhist11;
    logic       aDEhist12;
    logic       aDEhist13;
    logic       aDEhist14;
    logic       aDEhist15;
    logic       aDEhistFont;
    logic [3:0] red_port_hist, red_port_hist_org;
    logic [3:0] green_port_hist, green_port_hist_org;
    logic [3:0] blue_port_hist, blue_port_hist_org;
    logic [7:0] bar_height_hist_org   [0:15];

    logic [11:0] filter_data;
    logic [11:0] filter_data2;
    

    always_comb begin
    //    {vgaRed, vgaGreen, vgaBlue} = O_RGB444_data;
        VGA_SIZE = rgb_sw[0];
    end


    assign G_up_btn = (gamma_sw) ? btn[0] : 1'bz;
    assign G_down_btn = (gamma_sw) ? btn[1] : 1'bz;
    assign B_up_btn = (bright_sw) ? btn[0] : 1'bz;
    assign B_down_btn = (bright_sw) ? btn[1] : 1'bz;
    

    clock_div #(
        .FCOUNT(4)
    ) U_PIXEL_GENERATOR_filter (
        .*,
        .clk(clk),
        .o_clk(clk_25)
    );
    
    SCCB_intf U_SCCB(
        .clk(clk),
        .reset(reset),
        .SCL(SCL),
        .SDA(SDA)
    );

    vga_Controller U_vga_Controller (
        .clk             (clk),
        .reset           (reset),
        .Hsync           (Hsync),
        .Vsync           (Vsync),
        .display_en      (display_en),
        .x_coor          (x_coor),
        .y_coor          (y_coor),
        .r_clk           (r_clk),
        .pixel_clk       (ov7670_x_clk),
        .DE1             (DE1),
        .DE2             (DE2),
        .DE3             (DE3),
        .DE4             (DE4),
        .bar_height_hist (bar_height_hist),
        .DEhorizonLine   (DEhorizonLine),
        .DEverticalLine  (DEverticalLine),
        .DEhist0         (DEhist0),
        .DEhist1         (DEhist1),
        .DEhist2         (DEhist2),
        .DEhist3         (DEhist3),
        .DEhist4         (DEhist4),
        .DEhist5         (DEhist5),
        .DEhist6         (DEhist6),
        .DEhist7         (DEhist7),
        .DEhist8         (DEhist8),
        .DEhist9         (DEhist9),
        .DEhist10        (DEhist10),
        .DEhist11        (DEhist11),
        .DEhist12        (DEhist12),
        .DEhist13        (DEhist13),
        .DEhist14        (DEhist14),
        .DEhist15        (DEhist15),
        .DEhistFont      (DEhistFont),
        .abar_height_hist(bar_height_hist_org),
        .aDEhorizonLine  (aDEhorizonLine),
        .aDEverticalLine (aDEverticalLine),
        .aDEhist0        (aDEhist0),
        .aDEhist1        (aDEhist1),
        .aDEhist2        (aDEhist2),
        .aDEhist3        (aDEhist3),
        .aDEhist4        (aDEhist4),
        .aDEhist5        (aDEhist5),
        .aDEhist6        (aDEhist6),
        .aDEhist7        (aDEhist7),
        .aDEhist8        (aDEhist8),
        .aDEhist9        (aDEhist9),
        .aDEhist10       (aDEhist10),
        .aDEhist11       (aDEhist11),
        .aDEhist12       (aDEhist12),
        .aDEhist13       (aDEhist13),
        .aDEhist14       (aDEhist14),
        .aDEhist15       (aDEhist15),
        .aDEhistFont     (aDEhistFont)
    );

    ov7670_controller U_OV7670_MEM (
        .pclk(ov7670_pixel_clk),
        .reset(reset),
        .href(ov7670_href),
        .vsync(ov7670_vsync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    frame_buffer U_FRAME_BUFF (
        .wclk (ov7670_pixel_clk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk(r_clk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );
/*
    QVGA_MemController U_QVGA_MEM (
        .x_coor    (x_coor),
        .y_coor    (y_coor),
        .VGA_SIZE  (VGA_SIZE),
        .display_en(display_en),
        .de        (oe),
        .rAddr     (rAddr),
        .rData     (rData),
        .vgaRed    (BASE_RGB444_data[11:8]),
        .vgaGreen  (BASE_RGB444_data[7:4]),
        .vgaBlue   (BASE_RGB444_data[3:0])
    );
*/
    assign BASE_RGB444_data = rData;

    GrayScale_Filter U_GS_Filter (
        .data(BASE_RGB444_data),
        .RGBdata(GRAY_RGB444_data)
    );

    assign gray_org_data = (gray_sw) ? GRAY_RGB444_data : BASE_RGB444_data;

    VGA_Output_Processor U_VGA_OUTPUT (
        .i_clk          (r_clk),
        .reset        (reset),
        .vga_size_mode(VGA_SIZE),
        .display_en   (display_en),
        .x_coor       (x_coor),
        .y_coor       (y_coor),
        .fb_rdata     (filter_data),
        .fb_oe        (oe),
        .soe          (soe),
        .fb_rAddr     (rAddr),
        .vgaRed       (vgaRed),
        .vgaGreen     (vgaGreen),
        .vgaBlue      (vgaBlue)
    );


    Gamma_Filter U_GAMMA (
        .clk(clk_25),
        .reset(reset), 
        .up_btn(G_up_btn),
        .down_btn(G_down_btn),
        .rgb_in(gray_org_data),
        .rgb_out(GAMMA_RGB444_data)
    );

    BrightController U_BRIGHT(
        .clk(clk_25),
        .reset(reset),
        .i_data(GAMMA_RGB444_data),
        .up_btn(B_up_btn),
        .down_btn(B_down_btn),
        .o_data(BRIGHT_RGB444_data)
    );    
    

    ISP U_ISP (
        .i_clk(r_clk),
        .reset(reset),
        .rgb_sw(rgb_sw),
        .i_DE1_sw(DE1_sw),
        .i_DE3_sw(DE3_sw),
        .btn(btn),
        .g_btn(g_btn),
        .x_coor(x_coor),
        .y_coor(y_coor),
        .oe(oe),
        .BASE_RGB444_data(BRIGHT_RGB444_data),
        .BASE_RGB444_data2(gray_org_data),
        .O_RGB444_data(filter_data),
        .O_RGB444_data2(filter_data2)
    );

    histogram U_histogram (
        .clk(clk_25),
        .reset(reset),
        .x_pixel(x_coor),
        .y_pixel(y_coor),
        .red_port_after(vgaRed),        // 그레이스케일 값 입력
        .DE1(DE1),
        .DE2(DE2),
        .v_sync(Vsync),
        .red_port_hist(red_port_hist),
        .green_port_hist(green_port_hist),
        .blue_port_hist(blue_port_hist),
        .DEhorizonLine(DEhorizonLine),
        .DEverticalLine(DEverticalLine),
        .DEhist0(DEhist0),
        .DEhist1(DEhist1),
        .DEhist2(DEhist2),
        .DEhist3(DEhist3),
        .DEhist4(DEhist4),
        .DEhist5(DEhist5),
        .DEhist6(DEhist6),
        .DEhist7(DEhist7),
        .DEhist8(DEhist8),
        .DEhist9(DEhist9),
        .DEhist10(DEhist10),
        .DEhist11(DEhist11),
        .DEhist12(DEhist12),
        .DEhist13(DEhist13),
        .DEhist14(DEhist14),
        .DEhist15(DEhist15),
        .DEhistFont(DEhistFont),
        .bar_height_hist(bar_height_hist)  // 최종 막대 높이 : 업데이트 주기 10프레임
    );

    histogram2 U_histogram_after (
        .clk            (clk_25),
        .reset          (reset),
        .x_pixel        (x_coor),
        .y_pixel        (y_coor),
        .red_port_after (filter_data2[11:8]),                 // 원본 그레이스케일 값 입력 
        .DE1            (DE3),
        .DE2            (DE4),
        .v_sync         (Vsync),
        .red_port_hist  (red_port_hist_org),
        .green_port_hist(green_port_hist_org),
        .blue_port_hist (blue_port_hist_org),
        .DEhorizonLine  (aDEhorizonLine),
        .DEverticalLine (aDEverticalLine),
        .DEhist0        (aDEhist0),
        .DEhist1        (aDEhist1),
        .DEhist2        (aDEhist2),
        .DEhist3        (aDEhist3),
        .DEhist4        (aDEhist4),
        .DEhist5        (aDEhist5),
        .DEhist6        (aDEhist6),
        .DEhist7        (aDEhist7),
        .DEhist8        (aDEhist8),
        .DEhist9        (aDEhist9),
        .DEhist10       (aDEhist10),
        .DEhist11       (aDEhist11),
        .DEhist12       (aDEhist12),
        .DEhist13       (aDEhist13),
        .DEhist14       (aDEhist14),
        .DEhist15       (aDEhist15),
        .DEhistFont     (aDEhistFont),
        .bar_height_hist(bar_height_hist_org)        // 최종 막대 높이 : 업데이트 주기 10프레임
    );

    final_display U_display (
        .red_port_org(filter_data2[11:8]),
        .green_port_org(filter_data2[7:4]),
        .blue_port_org(filter_data2[3:0]),
        .red_port_after(vgaRed),
        .green_port_after(vgaGreen),
        .blue_port_after(vgaBlue),
        .red_port_hist(red_port_hist),
        .green_port_hist(green_port_hist),
        .blue_port_hist(blue_port_hist),
        .red_port_hist_org(red_port_hist_org),
        .green_port_hist_org(green_port_hist_org),
        .blue_port_hist_org(blue_port_hist_org),
        .red_port(red_port), //최종출력
        .green_port(green_port),
        .blue_port(blue_port),
        .DE1(DE1), 
        .DE2(DE2),
        .DE3(DE3),
        .DE4(DE4),
        .DEhistFont(DEhistFont)
    );
endmodule
