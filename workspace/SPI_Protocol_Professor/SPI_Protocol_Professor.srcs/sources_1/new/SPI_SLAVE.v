`timescale 1ns / 1ps

module SPI_SLAVE ();


endmodule

module SPI_SLAVE_Intf (
    // external signals
    input  SCLK,
    input  reset,
    input  MOSI,
    output MISO,
    input  SS,

    // internal signals
    output reg   write,
    output reg   done,
    output [1:0] addr,
    output [7:0] wdata,
    input  [7:0] rdata
);

    reg [7:0] temp_tx_data_reg;
    reg [7:0] temp_rx_data_reg;
    reg [2:0] bit_counter_reg;
    reg rden;

    assign MISO = SS ? 1'bz : temp_tx_data_reg[7];

    // MOSI sequence
    always @(posedge SCLK) begin
        if (SS == 1'b0) begin
            temp_rx_data_reg <= {temp_rx_data_reg[6:0], MOSI};
        end
    end

    // MISO sequence
    always @(negedge SCLK) begin
        if (SS == 1'b0 && !rden) begin
            temp_tx_data_reg <= rdata;
            rden <= 1'b1;
            bit_counter_reg <= 0;
        end
        else if (!SS && rden && !done) begin
            if (bit_counter_reg == 7) begin
                done <= 1'b1;
                bit_counter_reg <= 0;
            end
            else begin
                temp_tx_data_reg <= {temp_tx_data_reg[6:0], 1'b0};
                bit_counter_reg <= bit_counter_reg + 1;
            end
        end
        else if (SS) begin
            done <= 1'b0;
            rden <= 1'b0;
            bit_counter_reg <= 0;
        end
    end


endmodule
