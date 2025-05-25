`timescale 1ns / 1ps

module spi_top (
    input        clk,
    input        reset,
    input        cpol,
    input        cpha,
    input        start,
    input  [7:0] tx_data,
    output [7:0] rx_data,
    output       done,
    output       ready,
    
    input        SS
);

    wire SCLK, MOSI, MISO, so_done;

    SPI_Master U_SPI_MASTER (
        .clk(clk),
        .reset(reset),
        .cpol(cpol),
        .cpha(cpha),
        .start(start),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .done(done),
        .so_done(so_done),
        .ready(ready),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .SS(SS)
    );

    SPI_SLAVE U_SPI_SLAVE (
        .clk(clk),
        .reset(reset),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .SS(SS),
        .so_done(so_done)
    );


endmodule

module SPI_Master (
    //global signals
    input            clk,
    input            reset,
    //internal signals
    input            cpol,
    input            cpha,
    input            start,
    input      [7:0] tx_data,
    output  reg [7:0] rx_data,
    output reg       done,
     input            so_done,
    output reg       ready,
    //external port
    output           SCLK,
    output           MOSI,
    input            MISO,
    input            SS
);

    localparam IDLE = 0, CP_DELAY = 1, CP0 = 2, CP1 = 3;

    wire r_sclk;
    reg rx_read;
    reg [1:0] state, state_next;
    reg [7:0] temp_tx_data_next, temp_tx_data_reg;
    reg [7:0] temp_rx_data_next, temp_rx_data_reg;
    reg [5:0] sclk_counter_next, sclk_counter_reg;
    reg [2:0] bit_counter_next, bit_counter_reg;


    assign MOSI = (SS) ? 1'bz : temp_tx_data_reg[7];
    assign r_sclk = ((state_next == CP1) && ~cpha) ||
                    ((state_next == CP0) && cpha);
    //?��?�� 반전, ?���? ?��?��?��
    assign SCLK = cpol ? ~r_sclk : r_sclk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            sclk_counter_reg <= 0;
            bit_counter_reg  <= 0;
            rx_data <= 0;
        end else begin
            state            <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg  <= bit_counter_next;
            if (rx_read && tx_data == 0) begin
                rx_data <= temp_rx_data_reg;
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
        rx_read = 0;
        // r_sclk              = 0;
        case (state)
            IDLE: begin
                temp_tx_data_next = 0;
                ready             = 1;
                done              = 0;
                rx_read = 0;
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
                end else begin
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
                    if (bit_counter_reg == 6) begin
                        rx_read = 1;
                    end
                    if (bit_counter_reg == 7) begin
                        done       = 1;
                        state_next = IDLE;
                    end else begin
                        temp_tx_data_next = {
                            temp_tx_data_reg[6:0], 1'b0
                        };  //shift
                        sclk_counter_next = 0;
                        bit_counter_next = bit_counter_reg + 1;
                        state_next = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end
endmodule

module SPI_SLAVE (
    // external signals
    input  clk,
    input  reset,
    input  SCLK,
    input  MOSI,
    output MISO,
    input  SS,
    output so_done
);

    // internal signals
    wire [7:0] si_data;
    wire si_done;

    wire [7:0] so_data;
    wire so_start;
    // wire  so_done;


    SPI_SLAVE_Intf U_SPI_SLAVE_Intf (
        .clk     (clk),
        .reset   (reset),
        .SCLK    (SCLK),
        .MOSI    (MOSI),
        .MISO    (MISO),
        .SS      (SS),
        .si_data (si_data),
        .si_done (si_done),
        .so_data (so_data),
        .so_start(so_start),
        .so_done (so_done)
    );


    SPI_SLAVE_REG SPI_SLAVE_REG (
        .clk     (clk),
        .reset   (reset),
        .ss_n    (SS),
        .si_data (si_data),
        .si_done (si_done),
        .so_data (so_data),
        .so_start(so_start),
        .so_done (so_done)
    );


endmodule

module SPI_SLAVE_Intf (
    // external signals
    input  clk,
    input  reset,
    input  SCLK,
    input  MOSI,
    output MISO,
    input  SS,

    // internal signals
    output [7:0] si_data,
    output si_done,

    input [7:0] so_data,
    input so_start,
    output so_done
);


    reg sclk_sync0, sclk_sync1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 0;
            sclk_sync1 <= 0;
        end else begin
            sclk_sync0 <= SCLK;
            sclk_sync1 <= sclk_sync0;
        end
    end

    wire sclk_rising = sclk_sync0 & ~sclk_sync1;
    wire sclk_falling = ~sclk_sync0 & sclk_sync1;

    // SLAVE Input Circuit (MO_SI)
    localparam SI_IDLE = 0, SI_PHASE = 1;

    reg si_state, si_state_next;
    reg [7:0] si_data_reg, si_data_next;
    reg [2:0] si_bit_count_reg, si_bit_count_next;
    reg si_done_reg, si_done_next;


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            si_state <= SI_IDLE;
            si_data_reg <= 0;
            si_bit_count_reg <= 0;
            si_done_reg <= 0;
        end else begin
            si_state <= si_state_next;
            si_data_reg <= si_data_next;
            si_bit_count_reg <= si_bit_count_next;
            si_done_reg <= si_done_next;
        end
    end

    assign si_data = si_data_reg;
    assign si_done = si_done_reg;


    always @(*) begin
        si_state_next = si_state;
        si_data_next = si_data_reg;
        si_bit_count_next = si_bit_count_reg;
        si_done_next = 1'b0;
        case (si_state)
            SI_IDLE: begin
                if (!SS) begin
                    si_state_next = SI_PHASE;
                    si_bit_count_next = 0;
                end
            end
            SI_PHASE: begin
                if (!SS) begin
                    if (sclk_rising) begin
                        si_data_next = {si_data_reg[6:0], MOSI};
                        if (si_bit_count_reg == 7) begin
                            si_done_next = 1'b1;
                            si_bit_count_next = 0;
                            si_state_next = SI_IDLE;
                        end else begin
                            si_bit_count_next = si_bit_count_reg + 1;
                        end
                    end
                end else begin
                    si_state_next = SI_IDLE;
                end
            end
        endcase
    end

    // SLAVE Output Circuit (MI_SO)
    localparam SO_IDLE = 0, SO_PHASE = 1;

    reg so_state, so_state_next;
    reg [7:0] so_data_reg, so_data_next;
    reg [2:0] so_bit_count_reg, so_bit_count_next;
    reg so_done_reg, so_done_next;


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            so_state <= SO_IDLE;
            so_data_reg <= 0;
            so_bit_count_reg <= 0;
            so_done_reg <= 0;
        end else begin
            so_state <= so_state_next;
            so_data_reg <= so_data_next;
            so_bit_count_reg <= so_bit_count_next;
            so_done_reg <= so_done_next;
        end
    end

    assign so_done = so_done_reg;
    assign MISO = (SS) ? 1'bz : so_data_reg[7];

    always @(*) begin
        so_state_next = so_state;
        so_data_next = so_data_reg;
        so_bit_count_next = so_bit_count_reg;
        so_done_next = 1'b0;
        case (so_state)
            SO_IDLE: begin
                if (!SS && so_start) begin
                    so_state_next = SO_PHASE;
                    so_bit_count_next = 0;
                    so_data_next = so_data;
                end
            end
            SO_PHASE: begin
                if (!SS) begin
                    if (sclk_falling) begin
                        so_data_next = {so_data_reg[6:0], 1'b0};
                        if (so_bit_count_reg == 7) begin
                            so_bit_count_next = 0;
                            so_done_next = 1'b1;
                            so_state_next = SO_IDLE;
                        end else begin
                            so_bit_count_next = so_bit_count_reg + 1;
                        end

                    end
                end else begin
                    so_state_next = SO_IDLE;
                end
            end
        endcase
    end

endmodule


module SPI_SLAVE_REG (
    // global signals
    input            clk,
    input            reset,
    // internal signals
    input            ss_n,
    input      [7:0] si_data,
    input            si_done,
    output reg [7:0] so_data,
    output reg       so_start,
    input            so_done
    // input        so_ready
);

    localparam IDLE = 0, ADDR_PHASE = 1, WRITE_PHASE = 2, READ_PHASE = 3;

    reg [7:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    reg [7:0] slv_reg0_next, slv_reg1_next, slv_reg2_next, slv_reg3_next;
    reg [1:0] state, state_next;
    reg [1:0] addr, addr_next;
    reg so_start_next;
    reg [7:0] so_data_next;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            addr <= 2'bx;
            so_start <= 0;
            so_data <= 0;
            slv_reg0 <= 32'bx;
            slv_reg1 <= 32'bx;
            slv_reg2 <= 32'bx;
            slv_reg3 <= 32'bx;
        end else begin
            state <= state_next;
            addr <= addr_next;
            so_start <= so_start_next;
            so_data <= so_data_next;
            slv_reg0 <= slv_reg0_next;
            slv_reg1 <= slv_reg1_next;
            slv_reg2 <= slv_reg2_next;
            slv_reg3 <= slv_reg3_next;
        end
    end

    always @(*) begin
        state_next = state;
        addr_next = addr;
        so_start_next = 0;
        so_data_next = so_data;
        slv_reg0_next = slv_reg0;
        slv_reg1_next = slv_reg1;
        slv_reg2_next = slv_reg2;
        slv_reg3_next = slv_reg3;
        case (state)
            IDLE: begin
                if (!ss_n) begin
                    state_next = ADDR_PHASE;
                end
            end
            ADDR_PHASE: begin
                if (!ss_n) begin
                    if (si_done) begin
                        addr_next = si_data[1:0];
                        if (si_data[7]) begin
                            state_next = WRITE_PHASE;
                        end else begin
                            state_next = READ_PHASE;
                        end
                    end
                end

            end
            WRITE_PHASE: begin
                if (!ss_n) begin
                    if (si_done) begin
                        case (addr)
                            2'd0: slv_reg0_next = si_data;
                            2'd1: slv_reg1_next = si_data;
                            2'd2: slv_reg2_next = si_data;
                            2'd3: slv_reg3_next = si_data;
                        endcase
                        if (addr == 2'd3) begin
                            addr_next = 0;
                        end else begin
                            addr_next = addr + 1;
                        end
                    end
                end else begin
                    state_next = IDLE;
                end
            end
            READ_PHASE: begin
                if (!ss_n) begin
                    so_start_next = 1'b1;
                    case (addr)
                        2'd0: so_data_next = slv_reg0_next;
                        2'd1: so_data_next = slv_reg1_next;
                        2'd2: so_data_next = slv_reg2_next;
                        2'd3: so_data_next = slv_reg3_next;
                    endcase
                    if (so_done) begin
                        if (addr == 2'd3) begin
                            addr_next = 0;
                        end else begin
                            addr_next = addr + 1;
                        end
                    end

                end else begin
                    state_next = IDLE;
                end
            end
        endcase
    end

endmodule
