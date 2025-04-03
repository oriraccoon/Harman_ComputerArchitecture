`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        rst,
    input        sw_mode,
    input        sw_run_stop,
    input        sw_clear,
    output [3:0] fndCom,
    output [7:0] fndFont
);  
    wire [13:0] fndData;
    wire [ 3:0] fndDot;
    wire en, clear, mode;

    control_unit U_ControlUnit (
        .clk        (clk),
        .rst      (rst),
        .sw_mode    (sw_mode),
        .sw_run_stop(sw_run_stop),
        .sw_clear   (sw_clear),
        .en         (en),
        .clear      (clear),
        .mode       (mode)
    );

    counter_up_down U_Counter (
        .clk     (clk),
        .rst   (rst),
        .en      (en),
        .clear   (clear),
        .mode    (mode),
        .count   (fndData),
        .dot_data(fndDot)
    );

    fndController U_FndController (
        .clk    (clk),
        .rst  (rst),
        .fndData(fndData),
        .fndDot (fndDot),
        .fndCom (fndCom),
        .fndFont(fndFont)
    );
endmodule

module control_unit (
    input      clk,
    input      rst,
    input      sw_mode,
    input      sw_run_stop,
    input      sw_clear,
    output reg en,
    output reg clear,
    output reg mode
);
    localparam STOP = 0, RUN = 1, CLEAR = 2;
    reg [1:0] state, state_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= STOP;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        en         = 1'b0;
        clear      = 1'b0;
        mode       = sw_mode;
        case (state)
            STOP: begin
                en = 1'b0;
                clear = 1'b0;
                if (sw_run_stop) state_next = RUN;
                else if (sw_clear) state_next = CLEAR;
            end
            RUN: begin
                en = 1'b1;
                clear = 1'b0;
                if (sw_run_stop == 1'b0) state_next = STOP;
            end
            CLEAR: begin
                en = 1'b0;
                clear = 1'b1;
                if (sw_clear == 1'b0) state_next = STOP;
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
    input         mode,
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
