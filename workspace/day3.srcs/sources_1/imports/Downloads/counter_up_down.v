`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        rst,
    input        read_signal,
    input  [7:0] uart_data,
    output [3:0] fndCom,
    output [7:0] fndFont
);
    wire [13:0] fndData;
    wire [ 3:0] fndDot;
    wire en, clear;

    control_unit U_ControlUnit (
        .clk  (clk),
        .rst  (rst),
        .data (uart_data),
        .en   (en),
        .clear(clear)
    );

    counter_up_down U_Counter (
        .clk     (clk),
        .rst     (rst),
        .en      (en),
        .clear   (clear),
        .data    (uart_data),
        .count   (fndData),
        .dot_data(fndDot)
    );

    fndController U_FndController (
        .clk    (clk),
        .rst    (rst),
        .fndData(fndData),
        .fndDot (fndDot),
        .fndCom (fndCom),
        .fndFont(fndFont)
    );
endmodule

module control_unit (
    input            clk,
    input            rst,
    input      [7:0] data,
    output reg       en,
    output reg       clear
);
    localparam STOP = 0, RUN = 1, CLEAR = 2;
    reg [1:0] state, state_next, prev;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= STOP;
            prev <= STOP;
        end else begin
            state <= state_next;
            prev <= state;
        end
    end

    always @(*) begin
        state_next = state;
        en         = 1'b0;
        clear      = 1'b0;
        case (state)
            STOP: begin
                en = 1'b0;
                clear = 1'b0;
                if (data == "r" | "R") state_next = RUN;
                else if (data == "c" | "C") state_next = CLEAR;
            end
            RUN: begin
                en = 1'b1;
                clear = 1'b0;
                if (data == "r" | "R") state_next = STOP;
            end
            CLEAR: begin
                clear = 1'b1;
                state_next = prev;
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
    input         rst,
    input         en,
    input         clear,
    input         mode,
    output [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .rst(rst),
        .tick (tick),
        .en   (en),
        .clear(clear)
    );

    counter U_Counter_Up_Down (
        .clk  (clk),
        .rst(rst),
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
    input         rst,
    input         tick,
    input  [ 7:0] data,
    input         en,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter <= 0;
        end else begin
            if (clear) begin
                counter <= 0;
            end else begin
                if (en) begin
                    if (data == "p" | "P") begin
                        if (tick) begin
                            if (counter == 9999) begin
                                counter <= 0;
                            end else begin
                                counter <= counter + 1;
                            end
                        end
                    end else if (data == "m" | "M") begin
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
    input  wire rst,
    input  wire en,
    input  wire clear,
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
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
