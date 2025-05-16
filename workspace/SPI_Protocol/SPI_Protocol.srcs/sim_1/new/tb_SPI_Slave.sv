`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/16 16:24:44
// Design Name: 
// Module Name: tb_SPI_Slave
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
typedef enum {
    IDLE,
    SMODE0,
    SMODE1,
    SMODE2,
    SMODE3
} spi_mode_e;

module tb_SPI_Slave ();

    logic            clock;
    logic            reset;

    // SPI
    logic            MISO;
    wire             MOSI;
    wire             SCLK;
    wire             SS;
    logic            CPOL;
    logic            CPHA;

    // Data
    logic            start;
    logic      [7:0] tx_data;
    wire       [7:0] rx_data;
    wire             done;
    wire             m_ready;

    // internal
    spi_mode_e       state;
    wire             SCLK_RisingEdge_detect;
    wire             SCLK_FallingEdge_detect;
    wire       [7:0] data;

    wire s_done;

    SPI_Slave dut_slave (
        .*,
        .S_STATE(state),

        // Data
        .start(!m_ready),
        .done (s_done),
        .ready()

        // internal
    );


    SPI_Master dut (
        .*,
        .ready(m_ready)
    );
always #5 clock = ~clock;

initial begin
    clock = 0; reset = 1; MISO = 0; CPOL = 0; CPHA = 0; start = 0; tx_data = 0;
    #10 reset = 0;
    #10 start = 1; tx_data = 8'b10010011;
    #10 start = 0;
    @(posedge s_done);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    $finish;

end
endmodule
