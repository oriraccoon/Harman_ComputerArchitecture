module Gamma_Filter (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic        up_btn,
    input  logic        down_btn,
    input  logic [11:0] rgb_in,
    output logic ge,
    output logic [11:0] rgb_out
);

    logic [3:0] r_gamma_1_0, g_gamma_1_0, b_gamma_1_0;
    logic [3:0] r_gamma_1_8, g_gamma_1_8, b_gamma_1_8;
    logic [3:0] r_gamma_2_2, g_gamma_2_2, b_gamma_2_2;
    logic [3:0] r_gamma_0_5, g_gamma_0_5, b_gamma_0_5;

    typedef enum {
        G1_0,
        G1_8,
        G2_2,
        G0_5
    } state_e;

    state_e state;

    logic r_up_btn, r_down_btn;

    btn_edge_trigger U_UP_BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (reset),
        .i_btn(up_btn),
        .o_btn(r_up_btn)
    );
    btn_edge_trigger U_DOWN_BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (reset),
        .i_btn(down_btn),
        .o_btn(r_down_btn)
    );

    // -------------- 1.0 ---------------------
    gamma_rom_4bit_linear_g1_0 lut_r_g1_0 (
        .in_val(rgb_in[11:8]),
        .gamma_corrected(r_gamma_1_0)
    );
    gamma_rom_4bit_linear_g1_0 lut_g_g1_0 (
        .in_val(rgb_in[7:4]),
        .gamma_corrected(g_gamma_1_0)
    );
    gamma_rom_4bit_linear_g1_0 lut_b_g1_0 (
        .in_val(rgb_in[3:0]),
        .gamma_corrected(b_gamma_1_0)
    );

    // -------------- 1.8 ---------------------
    gamma_rom_4bit_g1_8 lut_r_g1_8 (
        .in_val(rgb_in[11:8]),
        .gamma_corrected(r_gamma_1_8)
    );
    gamma_rom_4bit_g1_8 lut_g_g1_8 (
        .in_val(rgb_in[7:4]),
        .gamma_corrected(g_gamma_1_8)
    );
    gamma_rom_4bit_g1_8 lut_b_g1_8 (
        .in_val(rgb_in[3:0]),
        .gamma_corrected(b_gamma_1_8)
    );

    // -------------- 2.2 ---------------------
    gamma_rom_4bit_g2_2 lut_r_g2_2 (
        .in_val(rgb_in[11:8]),
        .gamma_corrected(r_gamma_2_2)
    );
    gamma_rom_4bit_g2_2 lut_g_g2_2 (
        .in_val(rgb_in[7:4]),
        .gamma_corrected(g_gamma_2_2)
    );
    gamma_rom_4bit_g2_2 lut_b_g2_2 (
        .in_val(rgb_in[3:0]),
        .gamma_corrected(b_gamma_2_2)
    );

    // -------------- 0.5 ---------------------
    gamma_rom_4bit_g0_5 lut_r_g0_5 (
        .in_val(rgb_in[11:8]),
        .gamma_corrected(r_gamma_0_5)
    );
    gamma_rom_4bit_g0_5 lut_g_g0_5 (
        .in_val(rgb_in[7:4]),
        .gamma_corrected(g_gamma_0_5)
    );
    gamma_rom_4bit_g0_5 lut_b_g0_5 (
        .in_val(rgb_in[3:0]),
        .gamma_corrected(b_gamma_0_5)
    );


    always_ff @(posedge clk) begin
        if (en) begin
            ge <= 1'b1;
            if (r_up_btn) begin
                case (state)
                    G1_0: begin
                        state <= G1_8;
                    end
                    G1_8: begin
                        state <= G2_2;
                    end
                    G2_2: begin
                        state <= G0_5;
                    end
                    G0_5: begin
                        state <= G1_0;
                    end
                endcase
            end
            if (r_down_btn) begin
                case (state)
                    G1_0: begin
                        state <= G0_5;
                    end
                    G1_8: begin
                        state <= G1_0;
                    end
                    G2_2: begin
                        state <= G1_8;
                    end
                    G0_5: begin
                        state <= G2_2;
                    end
                endcase
            end
        end
        else begin
            ge <= 1'b0;
        end
    end

    always_comb begin
        rgb_out = {r_gamma_1_0, g_gamma_1_0, b_gamma_1_0};
        case (state)
            G1_0: begin
                rgb_out = {r_gamma_1_0, g_gamma_1_0, b_gamma_1_0};
            end
            G1_8: begin
                rgb_out = {r_gamma_1_8, g_gamma_1_8, b_gamma_1_8};
            end
            G2_2: begin
                rgb_out = {r_gamma_2_2, g_gamma_2_2, b_gamma_2_2};
            end
            G0_5: begin
                rgb_out = {r_gamma_0_5, g_gamma_0_5, b_gamma_0_5};
            end
        endcase
    end

endmodule


module gamma_rom_4bit_linear_g1_0 (
    input  logic [3:0] in_val,          // 0~15
    output logic [3:0] gamma_corrected  // LUT[in_val]
);

    // LUT for Gamma = 1.0 (Linear, no correction)
    logic [3:0] lut[0:15];

    initial begin
        // Vout = Vin
        lut[0]  = 0;
        lut[1]  = 1;
        lut[2]  = 2;
        lut[3]  = 3;
        lut[4]  = 4;
        lut[5]  = 5;
        lut[6]  = 6;
        lut[7]  = 7;
        lut[8]  = 8;
        lut[9]  = 9;
        lut[10] = 10;
        lut[11] = 11;
        lut[12] = 12;
        lut[13] = 13;
        lut[14] = 14;
        lut[15] = 15;
    end

    assign gamma_corrected = lut[in_val];

endmodule

module gamma_rom_4bit_g1_8 (
    input  logic [3:0] in_val,          // 0~15
    output logic [3:0] gamma_corrected  // LUT[in_val]
);

    // LUT for Gamma = 1.8
    // Vout = round(15 * (Vin / 15.0)^(1/1.8))
    logic [3:0] lut[0:15];

    initial begin
        lut[0]  = 0;
        lut[1]  = 4;
        lut[2]  = 6;
        lut[3]  = 7;
        lut[4]  = 8;
        lut[5]  = 9;
        lut[6]  = 10;
        lut[7]  = 11;
        lut[8]  = 12;
        lut[9]  = 12;
        lut[10] = 13;
        lut[11] = 14;
        lut[12] = 14;
        lut[13] = 15;
        lut[14] = 15;
        lut[15] = 15;
    end

    assign gamma_corrected = lut[in_val];

endmodule

module gamma_rom_4bit_g2_2 (
    input  logic [3:0] in_val,          // 0~15
    output logic [3:0] gamma_corrected  // LUT[in_val]
);

    // LUT for Gamma = 2.2 (approximates sRGB)
    // Vout = round(15 * (Vin / 15.0)^(1/2.2))
    logic [3:0] lut[0:15];

    initial begin
        lut[0]  = 0;
        lut[1]  = 3;
        lut[2]  = 5;
        lut[3]  = 6;
        lut[4]  = 7;
        lut[5]  = 8;
        lut[6]  = 9;
        lut[7]  = 10;
        lut[8]  = 10;
        lut[9]  = 11;
        lut[10] = 12;
        lut[11] = 12;
        lut[12] = 13;
        lut[13] = 14;
        lut[14] = 14;
        lut[15] = 15;
    end

    assign gamma_corrected = lut[in_val];

endmodule

module gamma_rom_4bit_g0_5 (
    input  logic [3:0] in_val,          // 0~15
    output logic [3:0] gamma_corrected  // LUT[in_val]
);

    // LUT for Gamma = 0.5
    // Vout = round(15 * (Vin / 15.0)^(1/0.5)) = round(15 * (Vin / 15.0)^2)
    logic [3:0] lut[0:15];

    initial begin
        lut[0]  = 0;
        lut[1]  = 0;
        lut[2]  = 0;
        lut[3]  = 1;
        lut[4]  = 1;
        lut[5]  = 2;
        lut[6]  = 2;
        lut[7]  = 3;
        lut[8]  = 4;
        lut[9]  = 5;
        lut[10] = 7;
        lut[11] = 8;
        lut[12] = 10;
        lut[13] = 11;
        lut[14] = 13;
        lut[15] = 15;
    end

    assign gamma_corrected = lut[in_val];

endmodule
