module uart (
    input clk,
    input rst,
    input rx,


    output tx
);

    wire [7:0] data;

    baud_tick_gen u_baud_tick_gen (
        .clk(clk),
        .rst(rst),
        .br_tick(br_tick)
    );

    uart_tx u_uart_tx (
        .clk(clk),
        .rst(rst),
        .data(data),
        .start_trig(start_trig),
        .tick(br_tick),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx(tx)
    );

    uart_rx u_uart_rx (
        .clk(clk),
        .rst(rst),
        .start_trig(~rx),
        .rx(rx),
        .tick(br_tick),
        .data(data),
        .rx_done(rx_done)
    );

endmodule


module baud_tick_gen (
    input clk,
    input rst,
    output reg br_tick
);

    parameter BAUD_RATE = 115200;
    parameter TICK_TIMING = 100_000_000 / 115200 / 16;

    reg [$clog2(TICK_TIMING)-1:0] br_counter;

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            br_counter <= 0;
            br_tick <= 0;
        end
        else begin
            if (br_counter == TICK_TIMING - 1) begin
                br_counter <= 0;
                br_tick <= 1;
            end
            else begin
                br_counter <= br_counter + 1;
                br_tick <= 0;
            end
        end
    end

endmodule

module uart_tx (
    input clk,
    input rst,
    input [7:0] data,
    input start_trig,
    input tick,
    output reg tx_busy,
    output reg tx_done,
    output reg tx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state, state_next;
    reg [7:0] temp_data_reg, temp_data_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [3:0] br_tick_counter_reg, br_tick_counter_next;
    reg tx_reg, tx_next, tx_busy_reg, tx_busy_next, tx_done_reg, tx_done_next;

    

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            {state, temp_data_reg, bit_count_reg, br_tick_counter_reg, 
            tx_reg, tx_busy_reg, tx_done_reg, tx_busy, tx_done, tx} <=
            0;
        end
        else begin
            {state, temp_data_reg, bit_count_reg, br_tick_counter_reg, 
            tx_reg, tx_busy_reg, tx_done_reg} <=
            {state_next, temp_data_next, bit_count_next, br_tick_counter_next, 
            tx_next, tx_busy_next, tx_done_next};

            {tx_busy, tx_done, tx} <=
            {tx_busy_reg, tx_done_reg, tx_reg};

        end
    end

    always @(*) begin
        state_next = state;
        temp_data_next = temp_data_reg;
        bit_count_next = bit_count_reg;
        br_tick_counter_next = br_tick_counter_reg;
        tx_next = tx_reg;
        tx_busy_next <= tx_busy_reg;
        tx_done_next <= tx_done_reg;
        case (state)
            IDLE: begin
                tx_next = 1;
                bit_count_next = 0;
                br_tick_counter_next = 0;
                tx_done_next = 0;
                tx_busy_next = 0;
                if(start_trig) begin
                    state_next = START;
                    temp_data_next = data;
                end
            end
            START: begin
                tx_next = 0;
                tx_busy_next = 1;
                if (tick) begin
                    if (br_tick_counter_reg == 15) begin
                        br_tick_counter_next = 0;
                        state_next = DATA;
                    end
                    else begin
                        br_tick_counter_next = br_tick_counter_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = temp_data_reg[0];
                if (tick) begin
                    if (br_tick_counter_reg == 15) begin
                        br_tick_counter_next = 0;
                        if (bit_count_reg == 7) begin
                            state_next = STOP;
                        end
                        else begin
                            bit_count_next = bit_count_reg + 1;
                            temp_data_next = temp_data_reg >> 1;
                        end
                    end
                end
            end
            STOP: begin
                tx_next = 1;
                if (tick) begin
                    if (br_tick_counter_reg == 15) begin
                        tx_done_next = 1;
                        state_next = IDLE;
                    end
                    else begin
                        br_tick_counter_next = br_tick_counter_reg + 1;
                    end
                end
            end 
        endcase
    end

endmodule


module uart_rx (
    input clk,
    input rst,
    input start_trig,
    input rx,
    input tick,
    output reg [7:0] data,
    output reg rx_done
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state, state_next;
    reg [7:0] temp_data_reg, temp_data_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [4:0] br_tick_counter_reg, br_tick_counter_next;
    reg rx_done_reg, rx_done_next;

    

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            {state, temp_data_reg, bit_count_reg, br_tick_counter_reg, 
            rx_done_reg,rx_done} <=
            0;
        end
        else begin
            {state, temp_data_reg, bit_count_reg, br_tick_counter_reg, 
            rx_done_reg} <=
            {state_next, temp_data_next, bit_count_next, br_tick_counter_next, 
            rx_done_next};

            {rx_done, data} <=
            {rx_done_reg, temp_data_next};

        end
    end

    always @(*) begin
        state_next = state;
        temp_data_next = temp_data_reg;
        bit_count_next = bit_count_reg;
        br_tick_counter_next = br_tick_counter_reg;
        rx_done_next <= rx_done_reg;
        case (state)
            IDLE: begin
                bit_count_next = 0;
                br_tick_counter_next = 0;
                rx_done_next = 0;
                if(start_trig) begin
                    state_next = START;
                end
            end
            START: begin
                if (tick) begin
                    if (br_tick_counter_reg == 7) begin
                        br_tick_counter_next = 0;
                        state_next = DATA;
                    end
                    else begin
                        br_tick_counter_next = br_tick_counter_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick) begin
                    if (br_tick_counter_reg == 15) begin
                        temp_data_next[7] = rx;
                        br_tick_counter_next = 0;
                        if (bit_count_reg == 7) begin
                            state_next = STOP;
                        end
                        else begin
                            bit_count_next = bit_count_reg + 1;
                            temp_data_next = {1'b0, temp_data_next[7:1]};
                        end
                    end
                end
            end
            STOP: begin
                if (tick) begin
                    if (br_tick_counter_reg == 23) begin
                        rx_done_next = 1;
                        state_next = IDLE;
                    end
                    else begin
                        br_tick_counter_next = br_tick_counter_reg + 1;
                    end
                end
            end 
        endcase
    end

endmodule
