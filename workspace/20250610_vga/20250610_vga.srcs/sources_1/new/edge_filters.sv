`timescale 1ns / 1ps

module edge_filters(
    input logic clk,
    );

    Laplasian_Filter U_LAPLA(
        .*,
        .de(me),
        .laen(laen),
        .g_data(SECOND_RGB444_data),
        .l_data(LAPLA_RGB444_data),
        .ls_data(L_SHARP_RGB444_data)
    );

    Sobel_Filter U_SOBEL(
        .*,
        .gray_in(SECOND_RGB444_data),
        .de(me),
        .sobel_out(SOBEL_RGB444_data),
        .scharr_out(SCHARR_RGB444_data),
        .s_sobel(S_SHARP_RGB444_data),
        .s_scharr(C_SHARP_RGB444_data)
    );

    Mopology_Filter U_MOPOL_AFTER_EDGE (
        .*,
        .i_data(THIRD_RGB444_data),
        .DE(le),             
        .moe(),             
        .o_data(EDGE_MOPOL_RGB444_data)  
    );


endmodule
