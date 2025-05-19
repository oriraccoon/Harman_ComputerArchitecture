`timescale 1ns / 1ps

import spi_mode_pkg::*;

module SPI_TOP (
    // General
    input logic clock,
    input logic reset,

    // Data
    input logic       btn,
    input logic [7:0] tx_data,

    output logic [3:0] fndCom,
    output logic [7:0] fndFont,

    input logic [7:0] sw
);

    // SPI_Master
    wire       MISO;
    wire       MOSI;
    wire       SCLK;
    wire       SS;
    logic      CPOL;
    logic      CPHA;
    wire       SCLK_RisingEdge_detect;
    wire       SCLK_FallingEdge_detect;

    wire       m_tx_done;
    wire       m_tx_ready;
    wire       m_rx_done;
    wire       m_rx_ready;

    wire       s_tx_done;
    wire       s_tx_ready;
    wire       s_rx_done;
    wire       s_rx_ready;
    
    spi_mode_e state;
    wire       m_rx_signal;
    wire       s_rx_signal;


    initial begin
        CPOL = 0;
        CPHA = 0;
    end


    SPI_Master m (
        .*,
        .start(btn),
        .rx_data(),
        .end_signal(s_rx_done),
        .s_rx_signal(s_rx_signal),
        .m_rx_signal(m_rx_signal),
        .tx_done(m_tx_done),
        .tx_ready(m_tx_ready),
        .rx_done(m_rx_done),
        .rx_ready(m_rx_ready)
    );

    Segment_SPI s (
        .*,
        .S_STATE(state),
        .s_rx_signal(s_rx_signal),
        .m_rx_signal(m_rx_signal),
        // Data
        .start(!m_tx_ready),
        .tx_done(s_tx_done),
        .tx_ready(s_tx_ready),
        .rx_done(s_rx_done),
        .rx_ready(s_rx_ready)
    );
endmodule
