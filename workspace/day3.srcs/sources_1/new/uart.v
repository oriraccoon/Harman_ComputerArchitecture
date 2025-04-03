`timescale 1ns / 1ps

module uart (
    // global port
    input        clk,
    input        rst,
    // tx side port
    input  [7:0] tx_data,
    input        tx_start,
    output       tx_busy,
    output       tx_done,
    output       tx,
    // rx side port
    output [7:0] rx_data,
    output       rx_done,
    input        rx
);

    wire br_tick;

    baudrate_gen U_baudrate_gen (
        .clk    (clk),
        .rst    (rst),
        .br_tick(br_tick)
    );

    transmitter U_transmitter (
        .clk     (clk),
        .rst     (rst),
        .tx_data (tx_data),
        .tx_start(tx_start),
        .br_tick (br_tick),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        .tx      (tx)
    );

    receiver U_receiver (
        .clk(clk),
        .rst(rst),
        .br_tick(br_tick),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx(rx)
    );

endmodule


module baudrate_gen (
    input      clk,
    input      rst,
    output reg br_tick
);

    reg [9:0] br_counter;  // '100_000_000 / 9600 / 16 - 1'에 필요한 비트수: 14비트

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            br_counter <= 0;
            br_tick <= 1'b0;
        end else begin
            if (br_counter == 100_000_000 / 9600 / 16 - 1) begin  // baudrate 값과 샘플링 16번 계산
                br_counter <= 0;
                br_tick <= 1'b1;
            end else begin
                br_counter <= br_counter + 1;
                br_tick <= 1'b0;
            end
        end
    end

endmodule


module transmitter (
    input            clk,
    input            rst,
    input      [7:0] tx_data,
    input            tx_start,
    input            br_tick,
    output           tx_busy,
    output           tx_done,
    output reg       tx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state, state_next;  // 상태 4개라 2비트
    reg [7:0] temp_data_reg, temp_data_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg [3:0] tick_counter_reg, tick_counter_next;
    reg tx_busy_reg, tx_busy_next;
    reg tx_done_reg, tx_done_next;

    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= IDLE;
            temp_data_reg    <= 0;
            bit_counter_reg  <= 0;
            tick_counter_reg <= 0;
            tx_busy_reg      <= 1'b0;
            tx_done_reg      <= 1'b0;
        end else begin
            state            <= state_next;
            temp_data_reg    <= temp_data_next;
            bit_counter_reg  <= bit_counter_next;
            tick_counter_reg <= tick_counter_next;
            tx_busy_reg      <= tx_busy_next;
            tx_done_reg      <= tx_done_next;
        end
    end

    always @(*) begin
        state_next        = state;
        temp_data_next    = temp_data_reg;
        bit_counter_next  = bit_counter_reg;
        tick_counter_next = tick_counter_reg;
        tx_busy_next      = tx_busy_reg;
        tx_done_next      = tx_done_reg;
        case (state)
            IDLE: begin
                tx           = 1'b1;
                tx_busy_next = 1'b0;
                tx_done_next = 1'b0;
                if (tx_start) begin
                    state_next     = START;
                    temp_data_next = tx_data;
                    tx_busy_next   = 1'b1;
                end
            end
            START: begin
                tx = 1'b0;
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin
                        state_next = DATA;
                        tick_counter_next = 0;
                        bit_counter_next = 0;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            DATA: begin
                tx = temp_data_reg[0];
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin
                        tick_counter_next = 0;
                        if (bit_counter_reg == 7) begin
                            state_next = STOP;
                        end else begin
                            bit_counter_next = bit_counter_reg + 1;
                            temp_data_next   = {1'b0, temp_data_reg[7:1]};
                        end
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            STOP: begin
                tx = 1'b1;
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin
                        state_next        = IDLE;
                        tick_counter_next = 0;
                        tx_done_next      = 1'b1;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule


module receiver (
    input        clk,
    input        rst,
    input        br_tick,
    output [7:0] rx_data,
    output       rx_done,
    input        rx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, state_next;
    reg rx_done_reg, rx_done_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg [3:0] tick_counter_reg, tick_counter_next;
    reg [7:0] temp_data_reg, temp_data_next;

    assign rx_data = temp_data_reg;
    assign rx_done = rx_done_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state            <= IDLE;
            rx_done_reg      <= 1'b0;
            bit_counter_reg  <= 0;
            tick_counter_reg <= 0;
            temp_data_reg    <= 0;
        end else begin
            state            <= state_next;
            rx_done_reg      <= rx_done_next;
            bit_counter_reg  <= bit_counter_next;
            tick_counter_reg <= tick_counter_next;
            temp_data_reg    <= temp_data_next;
        end
    end

    always @(*) begin
        state_next        = state;
        rx_done_next      = rx_done_reg;
        bit_counter_next  = bit_counter_reg;
        tick_counter_next = tick_counter_reg;
        temp_data_next    = temp_data_reg;
        case (state)
            IDLE: begin
                rx_done_next = 1'b0;
                if (rx == 1'b0) begin
                    state_next        = START;
                    bit_counter_next  = 0;
                    tick_counter_next = 0;
                    temp_data_next    = 0;
                end
            end
            START: begin
                if (br_tick) begin
                    if (tick_counter_reg == 7) begin
                        state_next = DATA;
                        tick_counter_next = 0;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            DATA: begin
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin
                        tick_counter_next = 0;
                        temp_data_next = {rx, temp_data_reg[7:1]};
                        if (bit_counter_reg == 7) begin
                            state_next = STOP;
                            bit_counter_next = 0;
                        end else begin
                            bit_counter_next = bit_counter_reg + 1;
                        end
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            STOP: begin
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin
                        rx_done_next = 1'b1;
                        state_next   = IDLE;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule
