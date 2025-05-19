`timescale 1ns / 1ps

import spi_mode_pkg::*;

module SPI_TOP(
        // General
        input logic clock,
        input logic reset,

        // Data
        input  logic       btn,
        input  logic [7:0] tx_data,
        output logic [7:0] data
);

        // SPI_Master
        wire MISO;
        wire MOSI;
        wire SCLK;
        wire SS;
        logic CPOL;
        logic CPHA;
        wire SCLK_RisingEdge_detect;
        wire SCLK_FallingEdge_detect;

        wire       m_done;
        wire       s_done;
        wire       m_ready;
        wire       s_ready;
        spi_mode_e  state;
        wire start_signal;
        
    
    
    initial begin
        CPOL = 0; CPHA = 1;
    end


    SPI_Master m(
        .*,
        .start(btn),
        .rx_data(),
        .end_signal(s_done),
        .done(m_done),
        .ready(m_ready)
    );

    SPI_Slave s(
        .*,
        .S_STATE(state),

        // Data
        .start(!ready),
        .done(s_done),
        .ready(s_ready)
    );
endmodule
