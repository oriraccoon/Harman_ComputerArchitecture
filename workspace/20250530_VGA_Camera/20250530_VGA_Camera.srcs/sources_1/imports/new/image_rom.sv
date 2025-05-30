`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05>>19 11:14:09
// Design Name: 
// Module Name: image_rom
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

module image_processing (
    input logic clk,
    input logic [4:0] c_sw,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic display_en,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic [15:0] image_data
);
    localparam WHITE_X_COOR = 91, YELLOW_X_COOR = 182, CYAN_X_COOR = 273, GREEN_X_COOR = 364, MAGENTA_X_COOR = 455, RED_X_COOR = 546, BLUE_X_COOR = 640;
    localparam FIRST_Y_COOR = 320, SECOND_Y_COOR = 360, THIRD_Y_COOR = 480;
    localparam LAST1_X_COOR = 111, LAST2_X_COOR = 222, LAST3_X_COOR = 333, LAST4_X_COOR = 455, LAST5_X_COOR = 485, LAST6_X_COOR = 515, LAST7_X_COOR = 546, LAST8_X_COOR = 640;

    logic [14:0] image_addr1;
    logic [15:0] image_data1; // RGB565 -> 16'b rrrrr_gggggg_bbbbb
    logic [14:0] image_addr2;
    logic [15:0] image_data2; // RGB565 -> 16'b rrrrr_gggggg_bbbbb
    logic [14:0] image_addr3;
    logic [15:0] image_data3; // RGB565 -> 16'b rrrrr_gggggg_bbbbb
    
    always_comb begin
        if (display_en) begin

            case (c_sw)
                5'b00001: begin
                    // 4분할
                    if ((y_coor < 240) && (x_coor < 320)) begin
                        image_addr1 = 160 * (y_coor >> 1) + (x_coor >> 1);
                        image_addr2 = 17'bz;
                        image_addr3 = 17'bz;
                        {vgaRed, vgaGreen, vgaBlue} = {image_data1[15:12], image_data1[10:7], image_data1[4:1]};
                        image_data = image_data1;
                    end
                    else if ((y_coor < 240) && (x_coor >= 320)) begin
                        image_addr2 = 160 * (y_coor >> 1) + ((x_coor - 320) >> 1);
                        image_addr1 = 17'bz;
                        image_addr3 = 17'bz;
                        {vgaRed, vgaGreen, vgaBlue} = {image_data2[15:12], image_data2[10:7], image_data2[4:1]};
                        image_data = image_data2;
                    end
                    else if ((y_coor >= 240) && (x_coor < 320)) begin
                        image_addr3 = 160 * ((y_coor - 240) >> 1) + (x_coor>>1);
                        image_addr2 = 17'bz;
                        image_addr1 = 17'bz;
                        {vgaRed, vgaGreen, vgaBlue} = {image_data3[15:12], image_data3[10:7], image_data3[4:1]};
                        image_data = image_data3;
                    end
                    // 3번 사진 뒤집기
                    else if ((y_coor >= 240) && (x_coor >= 320)) begin
                        image_addr3 = 160 * (120 - ((y_coor - 240) >> 1)) + (160 - ((x_coor - 320) >> 1));
                        image_addr2 = 17'bz;
                        image_addr1 = 17'bz;
                        {vgaRed, vgaGreen, vgaBlue} = {image_data3[15:12], image_data3[10:7], image_data3[4:1]};
                        image_data = image_data3;
                    end
                    else begin
                        image_addr1 = 17'bz;
                        image_addr2 = 17'bz;
                        image_addr3 = 17'bz;
                        {vgaRed, vgaGreen, vgaBlue} = 12'b0;
                    end
                end 
                5'b00011: begin
                    // 전체화면
                    image_addr1 = 160 * (y_coor >> 2) + (x_coor >> 2);
                    image_addr2 = 17'bz;
                    image_addr3 = 17'bz;
                    {vgaRed, vgaGreen, vgaBlue} = {image_data1[15:12], image_data1[10:7], image_data1[4:1]};
                    image_data = image_data1;
                end 
                5'b00101: begin
                    // 전체화면
                    image_addr2 = 160 * (y_coor >> 2) + (x_coor >> 2);
                    image_addr1 = 17'bz;
                    image_addr3 = 17'bz;
                    {vgaRed, vgaGreen, vgaBlue} = {image_data2[15:12], image_data2[10:7], image_data2[4:1]};
                    image_data = image_data2;
                end 
                5'b01001: begin
                    // 전체화면
                    image_addr3 = 160 * (y_coor >> 2) + (x_coor >> 2);
                    image_addr2 = 17'bz;
                    image_addr1 = 17'bz;
                    {vgaRed, vgaGreen, vgaBlue} = {image_data3[15:12], image_data3[10:7], image_data3[4:1]};
                    image_data = image_data3;
                end 
                5'b10001: begin
                    // 전체화면
                    image_addr3 = 160 * (120 - (y_coor >> 2)) + (160 - (x_coor >> 2));
                    image_addr2 = 17'bz;
                    image_addr1 = 17'bz;
                    {vgaRed, vgaGreen, vgaBlue} = {image_data3[15:12], image_data3[10:7], image_data3[4:1]};
                    image_data = image_data3;
                end 
                default: begin
                    image_addr1 = 17'bz;
                    image_addr2 = 17'bz;
                    image_addr3 = 17'bz;
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
                end
            endcase
            
        end
        else begin
            image_addr1 = 17'bz;
            image_addr2 = 17'bz;
            image_addr3 = 17'bz;
            {vgaRed, vgaGreen, vgaBlue} = 12'bz;
        end
        
    end

    image_async_rom1 U_ASYNC_ROM1(
        .addr(image_addr1),
        .data(image_data1)
    );
    image_async_rom2 U_ASYNC_ROM2(
        .addr(image_addr2),
        .data(image_data2)
    );
    image_async_rom3 U_ASYNC_ROM3(
        .addr(image_addr3),
        .data(image_data3)
    );
    // image_async_rom4 U_ASYNC_ROM4(
    //     .addr(image_addr4),
    //     .data(image_data3)
    // );

endmodule

module image_async_rom1 (
    input  logic [14:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom [0:160*120-1];

    initial begin
        $readmemh("QVGA_me.mem", rom);
    end

    always_comb begin
        data = rom[addr];
    end

endmodule
module image_async_rom2 (
    input  logic [14:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom [0:160*120-1];

    initial begin
        $readmemh("QVGA_snow1.mem", rom);
    end

    always_comb begin
        data = rom[addr];
    end

endmodule
module image_async_rom3 (
    input  logic [14:0] addr,
    output logic [15:0] data
);

    logic [15:0] rom [0:160*120-1];

    initial begin
        $readmemh("QVGA_snow2.mem", rom);
    end

    always_comb begin
        data = rom[addr];
    end

endmodule
// module image_async_rom4 (
//     input  logic [14:0] addr,
//     output logic [15:0] data
// );

//     logic [15:0] rom [0:160*120-1];

//     initial begin
//         $readmemh("QVGA_snow3.mem", rom);
//     end

//     always_comb begin
//         data = rom[addr];
//     end

// endmodule

// module image_sync_rom (
//     input  logic        clk,
//     input  logic [14:0] addr,
//     output logic [15:0] data
// );

//     logic [15:0] rom [0:320*240-1];

//     initial begin
//         $readmemh("QVGA_Lenna.mem", rom);
//     end

//     always_ff @(posedge clk) begin
//         data = rom[addr];
//     end

    
// endmodule