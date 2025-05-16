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

        wire       done;
        wire       ready;
        spi_mode_e  state;


    SPI_Master m(
        .*,
        .start(btn),
        .rx_data()
    );

    SPI_Slave s(
        .*,
        .S_STATE(state),

        // Data
        .start(!ready),
        .done(),
        .ready()
    );
endmodule
