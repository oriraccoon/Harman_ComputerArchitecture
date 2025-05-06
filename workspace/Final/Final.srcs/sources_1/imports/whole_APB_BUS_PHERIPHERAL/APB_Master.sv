`timescale 1ns / 1ps

module APB_Master (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic        PWRITE,
    output logic        PENABLE,
    output logic        PSEL0,      // RAM
    output logic        PSEL1,      // TIMER1
    output logic        PSEL2,      // GPIOA
    output logic        PSEL3,      // GPIOB
    output logic        PSEL4,      // GPIOC
    output logic        PSEL5,      // FND
    output logic        PSEL6,      // UltraSonic
    output logic        PSEL7,      // DHT-11
    output logic        PSEL8,      // BLINK
    output logic        PSEL9,      // TIMER2
    output logic        PSEL10,     // UART
    output logic        PSEL11,     // TILT
    output logic        PSEL12,     // RGB
    output logic        PSEL13,     // BUZZER
    input  logic [31:0] PRDATA0,
    input  logic [31:0] PRDATA1,
    input  logic [31:0] PRDATA2,
    input  logic [31:0] PRDATA3,
    input  logic [31:0] PRDATA4,
    input  logic [31:0] PRDATA5,
    input  logic [31:0] PRDATA6,
    input  logic [31:0] PRDATA7,
    input  logic [31:0] PRDATA8,
    input  logic [31:0] PRDATA9,
    input  logic [31:0] PRDATA10,
    input  logic [31:0] PRDATA11,
    input  logic [31:0] PRDATA12,
    input  logic [31:0] PRDATA13,
    input  logic        PREADY0,
    input  logic        PREADY1,
    input  logic        PREADY2,
    input  logic        PREADY3,
    input  logic        PREADY4,
    input  logic        PREADY5,
    input  logic        PREADY6,
    input  logic        PREADY7,
    input  logic        PREADY8,
    input  logic        PREADY9,
    input  logic        PREADY10,
    input  logic        PREADY11,
    input  logic        PREADY12,
    input  logic        PREADY13,
    // Internal Interface Signals
    input  logic        transfer,  // trigger signal
    output logic        ready,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic        write      // 1:write, 0:read
);
    logic [31:0] temp_addr_next, temp_addr_reg;
    logic [31:0] temp_wdata_next, temp_wdata_reg;
    logic temp_write_next, temp_write_reg;
    logic decoder_en;
    logic [13:0] pselx;

    assign PSEL0 = pselx[0];
    assign PSEL1 = pselx[1];
    assign PSEL2 = pselx[2];
    assign PSEL3 = pselx[3];
    assign PSEL4 = pselx[4];
    assign PSEL5 = pselx[5];
    assign PSEL6 = pselx[6];
    assign PSEL7 = pselx[7];
    assign PSEL8 = pselx[8];
    assign PSEL9 = pselx[9];
    assign PSEL10 = pselx[10];
    assign PSEL11 = pselx[11];
    assign PSEL12 = pselx[12];
    assign PSEL13 = pselx[13];

    typedef enum bit [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e state, state_next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            state          <= IDLE;
            temp_addr_reg  <= 0;
            temp_wdata_reg <= 0;
            temp_write_reg <= 0;
        end else begin
            state          <= state_next;
            temp_addr_reg  <= temp_addr_next;
            temp_wdata_reg <= temp_wdata_next;
            temp_write_reg <= temp_write_next;
        end
    end

    always_comb begin
        state_next      = state;
        temp_addr_next  = temp_addr_reg;
        temp_wdata_next = temp_wdata_reg;
        temp_write_next = temp_write_reg;
        PADDR           = temp_addr_reg;
        PWDATA          = temp_wdata_reg;
        PWRITE          = 1'b0;
        PENABLE         = 1'b0;
        decoder_en      = 1'b0;
        case (state)
            IDLE: begin
                decoder_en = 1'b0;
                if (transfer) begin
                    state_next      = SETUP;
                    temp_addr_next  = addr;  // latching
                    temp_wdata_next = wdata;
                    temp_write_next = write;
                end
            end
            SETUP: begin
                decoder_en = 1'b1;
                PENABLE    = 1'b0;
                PADDR      = temp_addr_reg;
                if (temp_write_reg) begin
                    PWRITE = 1'b1;
                    PWDATA = temp_wdata_reg;
                end else begin
                    PWRITE = 1'b0;
                end
                state_next = ACCESS;
            end
            ACCESS: begin
                decoder_en = 1'b1;
                PENABLE    = 1'b1;
                PADDR      = temp_addr_reg;
                if (temp_write_reg) begin
                    PWRITE = 1'b1;
                    PWDATA = temp_wdata_reg;
                end else begin
                    PWRITE = 1'b0;
                end
                if (ready) begin
                    state_next = IDLE;
                end
            end
        endcase
    end

    APB_Decoder U_APB_Decoder (
        .en (decoder_en),
        .sel(temp_addr_reg),
        .y  (pselx)
    );

    APB_Mux U_APB_Mux (
        .sel  (temp_addr_reg),
        .d0   (PRDATA0),
        .d1   (PRDATA1),
        .d2   (PRDATA2),
        .d3   (PRDATA3),
        .d4   (PRDATA4),
        .d5   (PRDATA5),
        .d6   (PRDATA6),
        .d7   (PRDATA7),
        .d8   (PRDATA8),
        .d9   (PRDATA9),
        .d10   (PRDATA10),
        .d11   (PRDATA11),
        .d12   (PRDATA12),
        .d13   (PRDATA13),
        .r0   (PREADY0),
        .r1   (PREADY1),
        .r2   (PREADY2),
        .r3   (PREADY3),
        .r4   (PREADY4),
        .r5   (PREADY5),
        .r6   (PREADY6),
        .r7   (PREADY7),
        .r8   (PREADY8),
        .r9   (PREADY9),
        .r10   (PREADY10),
        .r11   (PREADY11),
        .r12   (PREADY12),
        .r13   (PREADY13),
        .rdata(rdata),
        .ready(ready)
    );
endmodule

module APB_Decoder (
    input  logic        en,
    input  logic [31:0] sel,
    output logic [ 13:0] y
);
    always_comb begin
        y = 14'b0;
        if (en) begin
            casex (sel)
                32'h1000_0xxx: y = 14'b00000000000001;  // RAM
                32'h1000_10xx, 32'h1000_11xx, 32'h1000_12xx, 32'h1000_13xx: y = 14'b00000000000010;  // TIMER1
                32'h1000_14xx, 32'h1000_15xx, 32'h1000_16xx, 32'h1000_17xx: y = 14'b00000000000100;  // GPIOA
                32'h1000_18xx, 32'h1000_19xx, 32'h1000_1Axx, 32'h1000_1Bxx: y = 14'b00000000001000;  // GPIOB
                32'h1000_1Cxx, 32'h1000_1Dxx, 32'h1000_1Exx, 32'h1000_1Fxx: y = 14'b00000000010000;  // GPIOC
                32'h1000_20xx, 32'h1000_21xx, 32'h1000_22xx, 32'h1000_23xx: y = 14'b00000000100000;  // FND
                32'h1000_24xx, 32'h1000_25xx, 32'h1000_26xx, 32'h1000_27xx: y = 14'b00000001000000;  // UltraSonic
                32'h1000_28xx, 32'h1000_29xx, 32'h1000_2Axx, 32'h1000_2Bxx: y = 14'b00000010000000;  // DHT-11
                32'h1000_2Cxx, 32'h1000_2Dxx, 32'h1000_2Exx, 32'h1000_2Fxx: y = 14'b00000100000000;  // BLINK
                32'h1000_30xx, 32'h1000_31xx, 32'h1000_32xx, 32'h1000_33xx: y = 14'b00001000000000;  // TIMER2
                32'h1000_34xx, 32'h1000_35xx, 32'h1000_36xx, 32'h1000_37xx: y = 14'b00010000000000;  // UART
                32'h1000_38xx, 32'h1000_39xx, 32'h1000_3Axx, 32'h1000_3Bxx: y = 14'b00100000000000;  // TILT
                32'h1000_3Cxx, 32'h1000_3Dxx, 32'h1000_3Exx, 32'h1000_3Fxx: y = 14'b01000000000000;  // RGB
                32'h1000_40xx, 32'h1000_41xx, 32'h1000_42xx, 32'h1000_43xx: y = 14'b10000000000000;  // BUZZER
            endcase
        end
    end
endmodule

module APB_Mux (
    input  logic [31:0] sel,
    input  logic [31:0] d0,
    input  logic [31:0] d1,
    input  logic [31:0] d2,
    input  logic [31:0] d3,
    input  logic [31:0] d4,
    input  logic [31:0] d5,
    input  logic [31:0] d6,
    input  logic [31:0] d7,
    input  logic [31:0] d8,
    input  logic [31:0] d9,
    input  logic [31:0] d10,
    input  logic [31:0] d11,
    input  logic [31:0] d12,
    input  logic [31:0] d13,
    input  logic        r0,
    input  logic        r1,
    input  logic        r2,
    input  logic        r3,
    input  logic        r4,
    input  logic        r5,
    input  logic        r6,
    input  logic        r7,
    input  logic        r8,
    input  logic        r9,
    input  logic        r10,
    input  logic        r11,
    input  logic        r12,
    input  logic        r13,
    output logic [31:0] rdata,
    output logic        ready
);

    always_comb begin
        rdata = 32'bx;
        casex (sel)
            32'h1000_0xxx: rdata = d0;
            32'h1000_10xx, 32'h1000_11xx, 32'h1000_12xx, 32'h1000_13xx: rdata = d1;
            32'h1000_14xx, 32'h1000_15xx, 32'h1000_16xx, 32'h1000_17xx: rdata = d2;
            32'h1000_18xx, 32'h1000_19xx, 32'h1000_1Axx, 32'h1000_1Bxx: rdata = d3;
            32'h1000_1Cxx, 32'h1000_1Dxx, 32'h1000_1Exx, 32'h1000_1Fxx: rdata = d4;
            32'h1000_20xx, 32'h1000_21xx, 32'h1000_22xx, 32'h1000_23xx: rdata = d5;
            32'h1000_24xx, 32'h1000_25xx, 32'h1000_26xx, 32'h1000_27xx: rdata = d6;
            32'h1000_28xx, 32'h1000_29xx, 32'h1000_2Axx, 32'h1000_2Bxx: rdata = d7;
            32'h1000_2Cxx, 32'h1000_2Dxx, 32'h1000_2Exx, 32'h1000_2Fxx: rdata = d8;
            32'h1000_30xx, 32'h1000_31xx, 32'h1000_32xx, 32'h1000_33xx: rdata = d9;
            32'h1000_34xx, 32'h1000_35xx, 32'h1000_36xx, 32'h1000_37xx: rdata = d10;
            32'h1000_38xx, 32'h1000_39xx, 32'h1000_3Axx, 32'h1000_3Bxx: rdata = d11;
            32'h1000_3Cxx, 32'h1000_3Dxx, 32'h1000_3Exx, 32'h1000_3Fxx: rdata = d12;
            32'h1000_40xx, 32'h1000_41xx, 32'h1000_42xx, 32'h1000_43xx: rdata = d13;
        endcase
    end

    always_comb begin
        ready = 1'b0;
        casex (sel)
            32'h1000_0xxx: ready = r0;
            32'h1000_10xx, 32'h1000_11xx, 32'h1000_12xx, 32'h1000_13xx: ready = r1;
            32'h1000_14xx, 32'h1000_15xx, 32'h1000_16xx, 32'h1000_17xx: ready = r2;
            32'h1000_18xx, 32'h1000_19xx, 32'h1000_1Axx, 32'h1000_1Bxx: ready = r3;
            32'h1000_1Cxx, 32'h1000_1Dxx, 32'h1000_1Exx, 32'h1000_1Fxx: ready = r4;
            32'h1000_20xx, 32'h1000_21xx, 32'h1000_22xx, 32'h1000_23xx: ready = r5;
            32'h1000_24xx, 32'h1000_25xx, 32'h1000_26xx, 32'h1000_27xx: ready = r6;
            32'h1000_28xx, 32'h1000_29xx, 32'h1000_2Axx, 32'h1000_2Bxx: ready = r7;
            32'h1000_2Cxx, 32'h1000_2Dxx, 32'h1000_2Exx, 32'h1000_2Fxx: ready = r8;
            32'h1000_30xx, 32'h1000_31xx, 32'h1000_32xx, 32'h1000_33xx: ready = r9;
            32'h1000_34xx, 32'h1000_35xx, 32'h1000_36xx, 32'h1000_37xx: ready = r10;
            32'h1000_38xx, 32'h1000_39xx, 32'h1000_3Axx, 32'h1000_3Bxx: ready = r11;
            32'h1000_3Cxx, 32'h1000_3Dxx, 32'h1000_3Exx, 32'h1000_3Fxx: ready = r12;
            32'h1000_40xx, 32'h1000_41xx, 32'h1000_42xx, 32'h1000_43xx: ready = r13;
        endcase
    end
endmodule
