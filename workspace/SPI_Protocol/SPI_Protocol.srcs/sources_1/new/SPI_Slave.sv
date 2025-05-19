`timescale 1ns / 1ps

import spi_mode_pkg::*;

module Segment_SPI (
    // General
    input logic clock,
    input logic reset,

    // SPI_Slave
    input logic SCLK,
    input logic MOSI,
    input logic SS,
    output logic MISO,
    input spi_mode_e S_STATE,

    // Data
    input  logic start,
    input  logic s_rx_signal,
    output logic rx_done,
    output logic rx_ready,
    output logic tx_done,
    output logic tx_ready,
    output logic m_rx_signal,

    // internal
    input logic SCLK_RisingEdge_detect,
    input logic SCLK_FallingEdge_detect,

    output logic [3:0] fndCom,
    output logic [7:0] fndFont,
    input logic [7:0] sw
);

    logic [7:0] o_data;
    logic [7:0] i_data;

    assign i_data = sw;

    SPI_Slave SPI_S (.*);

    FndController seg_IP (
        .*,
        .fcr(1'b1),
        .fdr({6'b0, o_data}),
        .fpr(4'b0)
    );

endmodule


module SPI_Slave (
    // General
    input logic clock,
    input logic reset,

    // SPI_Slave
    input logic SCLK,
    input logic MOSI,
    input logic SS,
    output logic MISO,
    input spi_mode_e S_STATE,

    // Data
    input  logic start,
    input  logic s_rx_signal,
    output logic rx_done,
    output logic rx_ready,
    output logic tx_done,
    output logic tx_ready,
    output logic m_rx_signal,

    // internal
    input logic SCLK_RisingEdge_detect,
    input logic SCLK_FallingEdge_detect,
    output logic [7:0] o_data,
    input logic [7:0] i_data
);

    logic [7:0] rx_data;
    logic [7:0] tx_data;

    assign o_data = rx_data;
    assign tx_data = i_data;

    SPI_Slave_RXD U_SPI_RXD (
        .*,
        .start(s_rx_signal)
    );

    SPI_Slave_TXD U_SPI_TXD (
        .*,
        .start(!SS),
        .start_signal(m_rx_signal)
    );


endmodule

module SPI_Slave_RXD (
    input logic      clock,
    input logic      reset,
    input logic      SCLK,
    input logic      MOSI,
    input spi_mode_e S_STATE,
    input logic      SCLK_RisingEdge_detect,
    input logic      SCLK_FallingEdge_detect,
    input logic      start,

    output logic       rx_done,
    output logic       rx_ready,
    output logic [7:0] rx_data
);

    typedef enum {
        IDLE,
        START,
        DONE
    } state_e;
    state_e state, state_next;

    logic sclk_edge;
    logic [7:0] temp_rx_data_reg, temp_rx_data_next;
    logic [2:0] bit_count_reg, bit_count_next;


    always_comb begin
        case (S_STATE)
            SMODE0: begin
                sclk_edge = SCLK_RisingEdge_detect;
            end
            SMODE1: begin
                sclk_edge = SCLK_FallingEdge_detect;
            end
            SMODE2: begin
                sclk_edge = SCLK_FallingEdge_detect;
            end
            SMODE3: begin
                sclk_edge = SCLK_RisingEdge_detect;
            end
        endcase
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            temp_rx_data_reg <= 0;
            bit_count_reg <= 0;
        end else begin
            state <= state_next;
            temp_rx_data_reg <= temp_rx_data_next;
            bit_count_reg <= bit_count_next;
        end
    end

    always_comb begin
        state_next = state;
        rx_done = 1'b0;
        rx_ready = 1'b1;
        temp_rx_data_next = temp_rx_data_reg;
        bit_count_next = bit_count_reg;
        case (state)
            IDLE: begin
                if (start) begin
                    state_next = START;
                    rx_ready = 1'b0;
                    temp_rx_data_next = 8'b0;
                    bit_count_next = 0;
                end
            end
            START: begin
                rx_ready = 1'b0;
                if (sclk_edge) begin
                    if (bit_count_reg == 7) begin
                        temp_rx_data_next = temp_rx_data_next[6:0] << 1;
                        temp_rx_data_next[0] = MOSI;
                        state_next = DONE;
                        bit_count_next = 0;
                    end else begin
                        temp_rx_data_next = temp_rx_data_next[6:0] << 1;
                        temp_rx_data_next[0] = MOSI;
                        bit_count_next = bit_count_next + 1;
                    end
                end
            end
            DONE: begin
                rx_ready = 1'b0;
                rx_done = 1'b1;
                rx_data = temp_rx_data_reg;
                state_next = IDLE;
            end
        endcase
    end

endmodule

module SPI_Slave_TXD (
    input logic            clock,
    input logic            reset,
    input logic      [7:0] tx_data,
    input logic            SS,
    input spi_mode_e       S_STATE,
    input logic            SCLK_RisingEdge_detect,
    input logic            SCLK_FallingEdge_detect,
    input logic            start,

    output logic tx_done,
    output logic tx_ready,
    output logic start_signal,
    output logic MISO
);

    typedef enum {
        IDLE,
        START,
        DONE
    } state_e;
    state_e state, state_next;

    logic sclk_edge;
    logic [7:0] temp_tx_data_reg, temp_tx_data_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic MISO_temp;

    always_comb begin
        case (S_STATE)
            SMODE0: begin
                sclk_edge = SCLK_FallingEdge_detect;
            end
            SMODE1: begin
                sclk_edge = SCLK_RisingEdge_detect;
            end
            SMODE2: begin
                sclk_edge = SCLK_RisingEdge_detect;
            end
            SMODE3: begin
                sclk_edge = SCLK_FallingEdge_detect;
            end
        endcase
    end

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count_reg <= 0;
            temp_tx_data_reg <= 0;
        end else begin
            state <= state_next;
            bit_count_reg <= bit_count_next;
            temp_tx_data_reg <= temp_tx_data_next;
            if (SS) MISO <= 1'bz;
            else MISO <= MISO_temp;
        end
    end

    always_comb begin
        state_next = state;
        tx_done = 1'b0;
        tx_ready = 1'b1;
        start_signal = 1'b0;
        bit_count_next = bit_count_reg;
        temp_tx_data_next = temp_tx_data_reg;
        MISO_temp = MISO;
        case (state)
            IDLE: begin
                if (start) begin
                    state_next = START;
                    tx_ready = 1'b0;
                    temp_tx_data_next = tx_data;
                    bit_count_next = 0;
                end
            end
            START: begin
                tx_ready = 1'b0;
                if (sclk_edge) begin
                    start_signal = 1'b1;
                    if (bit_count_reg == 7) begin
                        MISO_temp = temp_tx_data_reg[7];
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        state_next = DONE;
                        bit_count_next = 0;
                    end else begin
                        MISO_temp = temp_tx_data_reg[7];
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        bit_count_next = bit_count_next + 1;
                    end
                end
            end
            DONE: begin
                tx_ready = 1'b0;
                tx_done = 1'b1;
                state_next = IDLE;
            end
        endcase
    end

endmodule

module FndController (
    input logic clock,
    input logic reset,
    input logic fcr,
    input logic [13:0] fdr,
    input logic [3:0] fpr,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
);

    logic o_clk;
    logic [3:0] digit1000, digit100, digit10, digit1;
    logic [27:0] blink_data;

    parameter LEFT = 16_000, RIGHT = 16_001, BOTH = 16_002;

    clock_divider #(
        .FCOUNT(100_000)
    ) U_1khz (
        .clk  (clock),
        .rst  (reset),
        .o_clk(o_clk)
    );

    digit_spliter U_digit_Spliter (
        .bcd(fdr),
        .digit1000(digit1000),
        .digit100(digit100),
        .digit10(digit10),
        .digit1(digit1)
    );

    function [6:0] bcd2seg(input [3:0] bcd);
        begin
            case (bcd)
                4'h0: bcd2seg = 7'h40;
                4'h1: bcd2seg = 7'h79;
                4'h2: bcd2seg = 7'h24;
                4'h3: bcd2seg = 7'h30;
                4'h4: bcd2seg = 7'h19;
                4'h5: bcd2seg = 7'h12;
                4'h6: bcd2seg = 7'h02;
                4'h7: bcd2seg = 7'h78;
                4'h8: bcd2seg = 7'h00;
                4'h9: bcd2seg = 7'h10;
                default: bcd2seg = 7'h7F;
            endcase
        end
    endfunction

    function [27:0] blink(input [13:0] bcd);
        begin
            case (bcd)
                LEFT: blink = {7'b0000110, 7'h3F, 7'h7F, 7'h7F};
                RIGHT: blink = {7'h7F, 7'h7F, 7'h3F, 7'b0110000};
                BOTH: blink = {7'b0000110, 7'h3F, 7'h3F, 7'b0110000};
                default: blink = {7'h7F, 7'h7F, 7'h7F, 7'h7F};
            endcase
        end
    endfunction

    always_ff @(posedge o_clk or posedge reset) begin
        if (reset) begin
            fndCom  = 4'b1110;
            fndFont = 8'hC0;
        end else begin
            if ((fdr < 10000) && fcr) begin
                case (fndCom)
                    4'b0111: begin
                        fndCom  <= 4'b1110;
                        fndFont <= {~fpr[0], bcd2seg(digit1)};
                    end
                    4'b1110: begin
                        fndCom  <= 4'b1101;
                        fndFont <= {~fpr[1], bcd2seg(digit10)};
                    end
                    4'b1101: begin
                        fndCom  <= 4'b1011;
                        fndFont <= {~fpr[2], bcd2seg(digit100)};
                    end
                    4'b1011: begin
                        fndCom  <= 4'b0111;
                        fndFont <= {~fpr[3], bcd2seg(digit1000)};
                    end
                    default: begin
                        fndCom  <= 4'b1110;
                        fndFont <= 8'hC0;
                    end
                endcase
            end else if ((fdr >= 10000) && fcr) begin
                blink_data = blink(fdr);
                case (fndCom)
                    4'b0111: begin
                        fndCom  <= 4'b1110;
                        fndFont <= {1'b1, blink_data[6:0]};
                    end
                    4'b1110: begin
                        fndCom  <= 4'b1101;
                        fndFont <= {1'b1, blink_data[13:7]};
                    end
                    4'b1101: begin
                        fndCom  <= 4'b1011;
                        fndFont <= {1'b1, blink_data[20:14]};
                    end
                    4'b1011: begin
                        fndCom  <= 4'b0111;
                        fndFont <= {1'b1, blink_data[27:21]};
                    end
                    default: begin
                        fndCom  <= 4'b1110;
                        fndFont <= 8'hC0;
                    end
                endcase
            end else if (!fcr) begin
                fndCom  <= 4'b1111;
                fndFont <= 8'hFF;
            end
        end
    end

endmodule

module clock_divider #(
    parameter FCOUNT = 100_000
) (
    input  logic clk,
    input  logic rst,
    output logic o_clk
);
    logic [$clog2(FCOUNT)-1:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            o_clk <= 0;
        end else begin
            if (count == FCOUNT - 1) begin
                o_clk <= 1;
                count <= 0;
            end else begin
                count <= count + 1;
                o_clk <= 0;
            end
        end
    end
endmodule


module digit_spliter #(
    parameter WIDTH = 14
) (
    input [WIDTH-1:0] bcd,
    output [3:0] digit1000,
    output [3:0] digit100,
    output [3:0] digit10,
    output [3:0] digit1
);

    assign digit1 = (bcd % 10);
    assign digit10 = (bcd % 100) / 10;
    assign digit100 = (bcd % 1000) / 100;
    assign digit1000 = bcd / 1000;

endmodule
