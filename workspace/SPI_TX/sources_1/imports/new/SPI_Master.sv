`timescale 1ns / 1ps

import spi_mode_pkg::*;

module SPI_Master (
    // General
    input logic clock,
    input logic reset,

    // SPI_Master
    input  logic MISO,
    output logic MOSI,
    output logic SCLK,
    output logic SS,
    input  logic CPOL,
    input  logic CPHA,

    // Data
    input  logic       start,
    input  logic [7:0] tx_data,
    input logic end_signal,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ready,
    output logic        start_signal,
    output spi_mode_e  state,

    // internal
    
    output logic SCLK_RisingEdge_detect,
    output logic SCLK_FallingEdge_detect
);

    logic prev_SCLK;
    logic cpol0sclk, cpol1sclk;
    logic o_clk;
    
    clock_div #(.FCOUNT(10)) c (
     .*,
     .start(!SS)
     );
    
    spi_mode_e state_next;

    assign SCLK_RisingEdge_detect = (SCLK && ~prev_SCLK) ? 1'b1 : 1'b0;
    assign SCLK_FallingEdge_detect = (!SCLK && prev_SCLK) ? 1'b1 : 1'b0;


    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            SS <= 1'b1;
        end else begin
            state <= state_next;
            prev_SCLK <= SCLK;
            if (start) begin
                SS <= 1'b0;
            end
            else if (end_signal) begin
                SS <= 1'b1;
            end
        end
    end
    
    always_ff @(posedge o_clk or posedge reset) begin
        if (reset) begin
            cpol0sclk <= 1'b0;
            cpol1sclk <= 1'b1;
        end
        else begin        
            cpol0sclk <= ~cpol0sclk;  // 1/2 clock
            cpol1sclk <= ~cpol1sclk;
        
        end
    end

    always_comb begin
        state_next = state;
        SCLK = 1'b0;
        case (state)
            IDLE: begin
                SCLK = 1'b0;
                case ({
                    CPHA, CPOL
                })
                    2'b00: state_next = SMODE0;
                    2'b01: state_next = SMODE1;
                    2'b10: state_next = SMODE2;
                    2'b11: state_next = SMODE3;
                endcase
            end
            SMODE0: begin
                // rising : rx data, falling : tx data
                SCLK = cpol0sclk;
                if ({CPHA, CPOL} != 2'b00) begin
                    state_next = IDLE;
                end

            end
            SMODE1: begin
                // rising : tx data, falling : rx data
                SCLK = cpol1sclk;
                if ({CPHA, CPOL} != 2'b01) begin
                    state_next = IDLE;
                end
            end
            SMODE2: begin
                // rising : tx data, falling : rx data
                SCLK = cpol0sclk;
                if ({CPHA, CPOL} != 2'b10) begin
                    state_next = IDLE;
                end
            end
            SMODE3: begin
                // rising : rx data, falling : tx data
                SCLK = cpol1sclk;
                if ({CPHA, CPOL} != 2'b11) begin
                    state_next = IDLE;
                end
            end
        endcase
    end

    // SPI_Master_RXD U_SPI_RXD(
    //     .*,
    //     .S_STATE(state),
    //     .start(!SS)
    // );

    SPI_Master_TXD U_SPI_TXD(
        .*,
        .S_STATE(state),
        .start(!SS)
    );

endmodule

module SPI_Master_RXD (
    input  logic            SCLK,
    input  logic            MISO,
    input  spi_mode_e       S_STATE,
    input  logic            SCLK_RisingEdge_detect,
    input  logic            SCLK_FallingEdge_detect,
    input  logic            start,

    output logic            done,
    output logic            ready,
    output logic      [7:0] rx_data
);

    typedef enum { IDLE, START, DONE } state_e;
    state_e state, state_next;

endmodule

module SPI_Master_TXD (
    input logic clock,
    input logic reset,
    input  logic      [7:0] tx_data,
    input logic SS,
    input  spi_mode_e       S_STATE,
    input  logic            SCLK_RisingEdge_detect,
    input  logic            SCLK_FallingEdge_detect,
    input  logic            start,

    output logic            done,
    output logic            ready,
    output logic            start_signal,
    output logic            MOSI
);

    typedef enum { IDLE, START, DONE } state_e;
    state_e state, state_next;

    logic sclk_edge;
    logic [7:0] temp_tx_data_reg, temp_tx_data_next;
    logic [3:0] bit_count_reg, bit_count_next;
    logic MOSI_temp;

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

always_ff @( posedge clock or posedge reset ) begin
    if (reset) begin
        state <= IDLE;
        bit_count_reg <= 0;
        temp_tx_data_reg <= 0;
    end
    else begin
        state <= state_next;
        bit_count_reg <= bit_count_next;
        temp_tx_data_reg <= temp_tx_data_next;
        if (SS) MOSI <= 1'bz;
        else MOSI <= MOSI_temp;
    end
end

    always_comb begin
        state_next = state;
        done = 1'b0;
        ready = 1'b1;
        start_signal = 1'b0;
        bit_count_next = bit_count_reg;
        temp_tx_data_next = temp_tx_data_reg;
        MOSI_temp = MOSI;
        case (state)
            IDLE: begin
                if (start) begin
                    state_next = START;
                    ready = 1'b0;
                    temp_tx_data_next = tx_data;
                    bit_count_next = 0;
                end
            end 
            START: begin
                ready = 1'b0;
                if (sclk_edge) begin
                    start_signal = 1'b1;
                    if (bit_count_reg == 8) begin
                        state_next = DONE;
                        bit_count_next = 0;
                    end
                    else begin
                        MOSI_temp = temp_tx_data_reg[7];
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        bit_count_next = bit_count_next + 1;                        
                    end
                end
            end
            DONE: begin
                ready = 1'b0;
                done = 1'b1;
                state_next = IDLE;
            end
        endcase
    end

endmodule

module demux1x4 (
    input logic SS,
    input logic [1:0] Ctrl,
    output logic [3:0] y
);



endmodule

module clock_div #(
    parameter FCOUNT = 2
) (
    input logic clock,
    input logic reset,
    input logic start,
    output logic o_clk
);

    logic [$clog2(FCOUNT)-1:0] count;
    
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            count <= 0;
            o_clk <= 0;
        end
        else begin
            if (start) begin
                if (count == (FCOUNT>>1)) begin
                    o_clk <= ~o_clk;
                    count <= 0;
                end
                else begin
                    count <= count + 1;
                end      
            end            
        end
    end

endmodule