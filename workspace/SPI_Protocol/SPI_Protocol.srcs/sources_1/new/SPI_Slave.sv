`timescale 1ns / 1ps

typedef enum {
    IDLE,
    SMODE0,
    SMODE1,
    SMODE2,
    SMODE3
} spi_mode_e;

module SPI_Slave (
    // General
    input logic clock,
    input logic reset,

    // SPI_Slave
    input  logic SCLK,
    input  logic MOSI,
    input  logic SS,
    output logic MISO,
    input spi_mode_e S_STATE,

    // Data
    input  logic       start,
    output logic       done,
    output logic       ready,

    // internal
    input logic SCLK_RisingEdge_detect,
    input logic SCLK_FallingEdge_detect,
    output logic [7:0] data
);

    logic [7:0] rx_data;

    assign data = rx_data;

    SPI_Slave_RXD U_SPI_RXD(
        .*
    );

endmodule

module SPI_Slave_RXD (
    input logic clock,
    input logic reset,
    input  logic            SCLK,
    input  logic            MOSI,
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

    logic sclk_edge;
    logic [7:0] temp_rx_data_reg, temp_rx_data_next;
    logic [2:0] bit_count;

    assign rx_data = temp_rx_data_reg;

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
            temp_rx_data_reg <= 0;
        end
        else begin
            state <= state_next;
            temp_rx_data_reg <= temp_rx_data_next;
        end
    end

    always_comb begin
        state_next = state;
        done = 1'b0;
        ready = 1'b1;
        temp_rx_data_next = temp_rx_data_reg;
        case (state)
            IDLE: begin
                if (start) begin
                    state_next = START;
                    ready = 1'b0;
                    temp_rx_data_next = 8'b0;
                    bit_count = 0;
                end
            end 
            START: begin
                ready = 1'b0;
                if (sclk_edge) begin
                    if (bit_count == 7) begin
                        state_next = DONE;
                        bit_count = 0;
                    end
                    else begin
                        temp_rx_data_next[0] = MOSI;
                        temp_rx_data_next = {temp_rx_data_next[6:0], 1'b0};
                        bit_count = bit_count + 1;                        
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

module SPI_Slave_TXD (
    input logic clock,
    input logic reset,
    input  logic      [7:0] tx_data,
    input  spi_mode_e       S_STATE,
    input  logic            SCLK_RisingEdge_detect,
    input  logic            SCLK_FallingEdge_detect,
    input  logic            start,

    output logic            done,
    output logic            ready,
    output logic            MOSI
);

    typedef enum { IDLE, START, DONE } state_e;
    state_e state, state_next;

    logic sclk_edge;
    logic [7:0] temp_tx_data;
    logic [2:0] bit_count;

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
        end
        else begin
            state <= state_next;
        end
    end

    always_comb begin
        state_next = state;
        done = 1'b0;
        ready = 1'b1;
        case (state)
            IDLE: begin
                MOSI = 1'bz;
                if (start) begin
                    state_next = START;
                    ready = 1'b0;
                    temp_tx_data = tx_data;
                    bit_count = 0;
                end
            end 
            START: begin
                ready = 1'b0;
                if (sclk_edge) begin
                    if (bit_count == 7) begin
                        state_next = DONE;
                        bit_count = 0;
                    end
                    else begin
                        MOSI = temp_tx_data[7];
                        temp_tx_data = {temp_tx_data[6:0], 1'b0};
                        bit_count = bit_count + 1;                        
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

module IP (
    input  logic [7:0] data,
    output logic [7:0] led
);

    assign led = data;

endmodule
