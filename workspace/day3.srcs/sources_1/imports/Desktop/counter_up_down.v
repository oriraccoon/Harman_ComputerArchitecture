`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    output [3:0] fndCom,
    output [7:0] fndFont,
    output       tx,
    input        rx

);
    wire [13:0] fndData;
    wire [ 3:0] fndDot;
    wire en, clear, mode;

    wire [7:0] rx_data;
    wire       rx_done;
    wire [7:0] tx_data;
    wire       tx_start;
    wire       tx_busy;
    wire       tx_done;

    uart U_uart (
        // global port
        .clk(clk),
        .reset(reset),
        // tx side port
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx(tx),
        // rx side port
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx(rx)
    );

    control_unit U_ControlUnit (
        .clk     (clk),
        .reset   (reset),
        // tx side port
        .tx_data (tx_data),
        .tx_start(tx_start),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        // rx side port
        .rx_data (rx_data),
        .rx_done (rx_done),
        // data path side port
        .en      (en),
        .clear   (clear),
        .mode    (mode)
    );

    counter_up_down U_Counter (
        .clk     (clk),
        .reset   (reset),
        .en      (en),
        .clear   (clear),
        .mode    (mode),
        .count   (fndData),
        .dot_data(fndDot)
    );

    fndController U_FndController (
        .clk    (clk),
        .reset  (reset),
        .fndData(fndData),
        .fndDot (fndDot),
        .fndCom (fndCom),
        .fndFont(fndFont)
    );

endmodule


module control_unit (
    input            clk,
    input            reset,
    // tx side port
    output reg [7:0] tx_data,
    output reg       tx_start,
    input            tx_busy,
    input            tx_done,
    // rx side port
    input      [7:0] rx_data,
    input            rx_done,
    // data path side port
    output reg       en,
    output reg       clear,
    output reg       mode
);
    localparam STOP = 0, RUN = 1, CLEAR = 2;
    localparam UP = 0, DOWN = 1;
    localparam IDLE = 0, ECHO = 1;

    reg [1:0] state, state_next;
    reg mode_state, mode_state_next;
    reg echo_state, echo_state_next;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state      <= STOP;
            mode_state <= UP;
            echo_state <= IDLE;
        end else begin
            state      <= state_next;
            mode_state <= mode_state_next;
            echo_state <= echo_state_next;
        end
    end

    always @(*) begin
        echo_state_next = echo_state;
        tx_data = 0;
        tx_start = 1'b0;
        case (echo_state)
            IDLE: begin
                tx_data  = 0;
                tx_start = 1'b0;
                if (rx_done) begin
                    echo_state_next = ECHO;
                end
            end
            ECHO: begin
                if (tx_done) begin
                    echo_state_next = IDLE;
                end else begin
                    tx_data  = rx_data;
                    tx_start = 1'b1;
                end
            end
        endcase
    end

    always @(*) begin
        mode_state_next = mode_state;
        mode = 1'b0;
        case (mode_state)
            UP: begin
                mode = 1'b0;
                if (rx_done) begin
                    if (rx_data == 8'h4d || rx_data == 8'h6d)
                        mode_state_next = DOWN;  // ASCII 'M', 'm'
                end
            end
            DOWN: begin
                mode = 1'b1;
                if (rx_done) begin
                    if (rx_data == 8'h4d || rx_data == 8'h6d)
                        mode_state_next = UP;  // ASCII 'M', 'm'
                end
            end
        endcase
    end

    always @(*) begin
        state_next = state;
        en         = 1'b0;
        clear      = 1'b0;
        case (state)
            STOP: begin
                en = 1'b0;
                clear = 1'b0;
                if (rx_done) begin
                    if (rx_data == 8'h72 || rx_data == 8'h52)
                        state_next = RUN;  // ASCII 'r', 'R'
                    else if (rx_data == 8'h63 || rx_data == 8'h43)
                        state_next = CLEAR;  // ASCII 'c', 'C'
                end
            end
            RUN: begin
                en = 1'b1;
                clear = 1'b0;
                if (rx_done) begin
                    if (rx_data == 8'h72 || rx_data == 8'h52) state_next = STOP;
                end
            end
            CLEAR: begin
                en = 1'b0;
                clear = 1'b1;
                state_next = STOP;
            end
        endcase
    end

endmodule


module comp_dot (
    input  [13:0] count,
    output [ 3:0] dot_data
);
    assign dot_data = ((count % 10) < 5) ? 4'b1101 : 4'b1111;

endmodule


module counter_up_down (
    input         clk,
    input         reset,
    input         en,
    input         clear,
    input         mode,
    output [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .en   (en),
        .clear(clear)
    );

    counter U_Counter_Up_Down (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .mode (mode),
        .en   (en),
        .clear(clear),
        .count(count)
    );

    comp_dot U_Comp_Dot (
        .count(count),
        .dot_data(dot_data)
    );

endmodule


module counter (
    input         clk,
    input         reset,
    input         tick,
    input         mode,
    input         en,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (clear) begin
                counter <= 0;
            end else begin
                if (en) begin
                    if (mode == 1'b0) begin
                        if (tick) begin
                            if (counter == 9999) begin
                                counter <= 0;
                            end else begin
                                counter <= counter + 1;
                            end
                        end
                    end else begin
                        if (tick) begin
                            if (counter == 0) begin
                                counter <= 9999;
                            end else begin
                                counter <= counter - 1;
                            end
                        end
                    end
                end
            end
        end
    end

endmodule


module clk_div_10hz (
    input  wire clk,
    input  wire reset,
    input  wire en,
    input  wire clear,
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (en) begin
                if (div_counter == 10_000_000 - 1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
            if (clear) begin
                div_counter <= 0;
                tick <= 1'b0;
            end
        end
    end
endmodule
