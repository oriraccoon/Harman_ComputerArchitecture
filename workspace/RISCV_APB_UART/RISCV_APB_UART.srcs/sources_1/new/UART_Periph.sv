`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/29 08:58:58
// Design Name: 
// Module Name: UART_Periph
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


module UART_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    input  logic        rx_data,
    output logic        tx_data_in
);
    logic rx_done;
    logic rx_empty;
    logic tx_empty, tx_full, tx_done;
    logic [7:0] rx_data;
    logic [7:0] rdata;
    logic [7:0] tx_data_in;

    always @(posedge clk or posedge rst) begin
        if(rst) tx_data_in = 0;
        else begin
            if(!tx_empty) tx_data_in = tx_data;
            else tx_data_in = tx_data_in;
        end
    end
    
    logic                   ucr;
    logic [$clog2(400)-1:0] udr;


    UART_IP U_UART (
        .clk(clk),
        .rst(rst),
        .btn_start((!tx_empty & ~tx_done)),
        .tx_data(tx_data_in),
        .tx_done(tx_done),
        .tx(tx),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .tick(tick)
    );

endmodule


module UART_IP (
    input  logic       clk,
    input  logic       rst,
    // tx
    input  logic       btn_start,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx,
    // rx
    input  logic       rx,
    output logic       rx_done,
    output logic [7:0] rx_data,
    output logic       tick

);

    logic w_tick;

    assign tick = w_tick;

    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .start_trigger(btn_start),
        .data_in(tx_data),
        .o_tx_done(tx_done),
        .o_tx(tx)
    );


    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    baud_tick_gen U_BAUD_Tick_Gen (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_tick)
    );

endmodule
module uart_tx (
    input  logic       clk,
    input  logic       rst,
    input  logic       tick,
    input  logic       start_trigger,
    input  logic [7:0] data_in,
    output logic       o_tx_done,
    output logic       o_tx
);
    // fsm state
    parameter IDLE = 0, SEND = 1, START = 2, DATA = 3, STOP = 4;

    logic [3:0] state, next;
    logic tx_reg, tx_next;
    logic tx_done_reg, tx_done_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [3:0] tick_count_reg, tick_count_next;
    assign o_tx_done = tx_done_reg;
    assign o_tx = tx_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_reg <= 1'b1;    //  Uart tx line을 초기에 항상 1로 만들기 위함.
            tx_done_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state          <= next;
            tx_reg         <= tx_next;
            tx_done_reg    <= tx_done_next;
            bit_count_reg  <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    // next
    always @(*) begin
        next            = state;
        tx_next         = tx_reg;
        tx_done_next    = tx_done_reg;
        bit_count_next  = bit_count_reg;
        tick_count_next = tick_count_reg;
        case (state)
            IDLE: begin
                tx_next = 1'b1;
                tx_done_next = 1'b0;
                tick_count_next = 4'h0;
                if (start_trigger) begin
                    next = SEND;
                end
            end
            SEND: begin
                if (tick == 1'b1) begin
                    next = START;
                end
            end
            START: begin
                tx_done_next = 1'b1;  //
                tx_next      = 1'b0;  // 출력을 0으로 유지.
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        next = DATA;
                        bit_count_next = 1'b0;
                        tick_count_next = 1'b0; // next state로 갈때 tick_count 초기화
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_in[bit_count_reg];  // UART LSB first

                if (tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0; // 다음 상태로 가기전에 초기화
                        if (bit_count_reg == 7) begin
                            next = STOP;
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;  // bit count 증가
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

// UART RX
module uart_rx (
    input  logic       clk,
    input  logic       rst,
    input  logic       tick,
    input  logic       rx,
    output logic       rx_done,
    output logic [7:0] rx_data
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    logic [1:0] state, next;
    logic rx_done_reg, rx_done_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [4:0] tick_count_reg, tick_count_next;  // rx tick max count 24.
    logic [7:0] rx_data_reg, rx_data_next;
    // output
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    // state
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            rx_done_reg    <= 0;
            rx_data_reg    <= 1;
            bit_count_reg  <= 0;
            tick_count_reg <= 0;
        end else begin
            state          <= next;
            rx_done_reg    <= rx_done_next;
            rx_data_reg    <= rx_data_next;
            bit_count_reg  <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    // next
    always @(*) begin
        next = state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        rx_done_next = 1'b0;
        rx_data_next = rx_data_reg;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next  = 0;
                rx_done_next    = 1'b0;
                if (rx == 1'b0) begin
                    next = START;
                end
            end
            START: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;  // init tick count
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        // read data 
                        rx_data_next[bit_count_reg] = rx;
                        if (bit_count_reg == 7) begin
                            next = STOP;
                            tick_count_next = 0;  // tick count 초기화
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                            tick_count_next = 0;  // tick count 초기화
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 23) begin
                        rx_done_next = 1'b1;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module baud_tick_gen (
    input  logic clk,
    input  logic rst,
    output logic baud_tick
);
    parameter BAUD_RATE = 115200;  //, BAUD_RATE_19200 = 19200, ;
    localparam BAUD_COUNT = 100_000_000 / BAUD_RATE / 16;
    logic [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;
    logic tick_reg, tick_next;
    // output
    assign baud_tick = tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    // next
    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule
