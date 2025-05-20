`timescale 1ns / 1ps

module SPI_Master (
    //global signals
    input            clk,
    input            reset,
    //internal signals
    input            cpol,
    input            cpha,
    input            start,
    input      [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg       done,
    input so_done,
    output reg       ready,
    //external port
    output           SCLK,
    output           MOSI,
    input            MISO,
    input            SS
);

    localparam IDLE = 0, CP_DELAY = 1, CP0 = 2, CP1 = 3;

    wire r_sclk;
    reg [1:0] state, state_next;
    reg [7:0] temp_tx_data_next, temp_tx_data_reg;
    reg [7:0] temp_rx_data_next, temp_rx_data_reg;
    reg [5:0] sclk_counter_next, sclk_counter_reg;
    reg [2:0] bit_counter_next, bit_counter_reg;


    assign MOSI    = (SS) ? 1'bz : temp_tx_data_reg[7];
    // assign rx_data = temp_rx_data_reg;
    assign r_sclk = ((state_next == CP1) && ~cpha) ||
                    ((state_next == CP0) && cpha);
    //클럭 반전, 유지 어사인
    assign SCLK = cpol ? ~r_sclk : r_sclk; 

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            sclk_counter_reg <= 0;
            bit_counter_reg  <= 0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
            if (so_done) begin
                rx_data = temp_rx_data_reg;
            end
        end
    end

    always @(*) begin
        state_next        = state;
        temp_tx_data_next = temp_tx_data_reg;
        temp_rx_data_next = temp_rx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next  = bit_counter_reg;
        ready             = 0;
        done              = 0;
        // r_sclk              = 0;
        case (state)
            IDLE: begin
                temp_tx_data_next = 0;
                ready             = 1;
                done              = 0;
                if (start) begin
                    temp_tx_data_next = tx_data;
                    ready             = 0;
                    sclk_counter_next = 0;
                    bit_counter_next  = 0;
                    state_next        = cpha ? CP_DELAY : CP0;
                end
            end
            CP_DELAY: begin
                if (sclk_counter_reg == 49) begin
                    state_next = CP0;
                    sclk_counter_next = 0;
                end
                else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP0: begin
                // r_sclk = 0;
                if (sclk_counter_reg == 49) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MISO};
                    sclk_counter_next = 0;
                    state_next        = CP1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                // r_sclk = 1;
                if (sclk_counter_reg == 49) begin
                    if (bit_counter_reg == 7) begin
                        done       = 1;
                        state_next = IDLE;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};  //shift
                        sclk_counter_next = 0;
                        bit_counter_next  = bit_counter_reg + 1;
                        state_next        = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule
