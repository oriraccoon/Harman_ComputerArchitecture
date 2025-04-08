`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    input rx,
    output [3:0] fndCom,
    output [7:0] fndFont,
    output tx
);
    wire [13:0] fndData;
    wire [ 3:0] dot_data;
    reg [7:0] buff_data, tick_data;
    wire [2:0] command;

    wire [7:0] rx_data;
    wire rx_done, tx_done;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            buff_data <= 8'b0;
            tick_data <= 0;
        end else begin
            if (rx_done) begin
                buff_data <= rx_data;
                tick_data <= rx_data;
            end else begin
                tick_data <= 0;
            end
        end
    end

    counter_up_down U_Counter (
        .clk(clk),
        .reset(reset),
        .mode(command),
        .run_stop_signal(run_stop_signal),
        .clear_signal(clear_signal),
        .count(fndData),
        .dot_data(dot_data)
    );

    fndController U_FndController (
        .clk(clk),
        .reset(reset),
        .fndData(fndData),
        .fndDot(dot_data),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );

    switch_ctrl U_Switch_ctrl (
        .clk(clk),
        .rst(reset),
        .ctrl(command),
        .run_stop_signal(run_stop_signal),
        .clear_signal(clear_signal)
    );

    uart U_uart(
        .clk(clk),
        .rst(reset),

        .btn_start(rx_done),
        .tx_data(buff_data),
        .tx_done(tx_done),
        .tx(tx),

        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    command U_Command (
        .clk(clk),
        .data(tick_data),
        .command(command)
    );

endmodule
// ---------------------------------------------------------------------------------
// DATA PATH
// ---------------------------------------------------------------------------------
module comp_dot (
    input  [13:0] count,
    output [ 3:0] dot_data
);
    assign dot_data = (count % 10 < 5) ? 4'b1101 : 4'b1111;

endmodule

module counter_up_down (
    input         clk,
    input         reset,
    input  [2:0]    mode,
    input         run_stop_signal,
    input         clear_signal,
    output [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    counter U_Counter_Up_Down (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .mode(mode),
        .run_stop_signal(run_stop_signal),
        .clear_signal(clear_signal),
        .count(count)
    );

    comp_dot U_Comp_dot (
        .count(count),
        .dot_data(dot_data)
    );

endmodule

module counter (
    input         clk,
    input         reset,
    input         tick,
    input  [2:0]    mode,
    input         run_stop_signal,
    input         clear_signal,
    output [13:0] count
);
    parameter IDLE = 0, PLUS_MOD = 1, MINUS_MOD = 2;

    reg [$clog2(10000)-1:0] counter;
    reg r_mod;

    initial r_mod = 0;

    always @(*) begin
        if(mode == PLUS_MOD) r_mod = 0;
        else if(mode == MINUS_MOD) r_mod = 1;
    end

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            case ({clear_signal, run_stop_signal})
                2'b10, 2'b11: counter <= 0;
                2'b01: begin
                        if (~r_mod) begin
                            if (tick) begin
                                if (counter == 9999) begin
                                    counter <= 0;
                                end else begin
                                    counter <= counter + 1;
                                end
                            end
                        end else if(r_mod) begin
                            if (tick) begin
                                if (counter == 0) begin
                                    counter <= 9999;
                                end else begin
                                    counter <= counter - 1;
                                end
                            end
                        end
                    end
                2'b00: counter <= counter;
            endcase
        end
    end
endmodule

module clk_div_10hz (
    input  wire clk,
    input  wire reset,
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (div_counter == 10_000_000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule

// ---------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------
// Control Unit
// ---------------------------------------------------------------------------------

module switch_ctrl (
    input clk,
    input rst,
    input [2:0] ctrl,
    output reg run_stop_signal,
    output reg clear_signal
);
    parameter IDLE = 0, RUN = 3, CLEAR = 4;
    reg [2:0] state, prev;

    initial begin
        state <= IDLE;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            prev <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    run_stop_signal <= 0;
                    clear_signal <= 0;
                    if(ctrl == RUN) state <= RUN;
                    if(ctrl == CLEAR) state <= CLEAR;
                end
                RUN: begin
                    run_stop_signal <= 1;
                    clear_signal <= 0;
                    if(ctrl == CLEAR) state <= CLEAR;
                    if(ctrl == RUN) state <= IDLE;
                end
                CLEAR: begin
                    clear_signal <= 1;
                    state <= prev;
                end
            endcase
        end
        prev <= state;
    end

endmodule


// ---------------------------------------------------------------------------------
// ---------------------------------------------------------------------------------


module command (
    input clk,
    input [7:0] data,
    output reg [2:0] command
);
    
    parameter IDLE = 0, PLUS_MOD = 1, MINUS_MOD = 2, RUN_MOD = 3, CLEAR = 4;

    always @(posedge clk) begin
        command <= IDLE;
        case (data)
            "p", "P" : command <= PLUS_MOD;
            "m", "M" : command <= MINUS_MOD; 
            "r", "R" : command <= RUN_MOD;
            "c", "C" : command <= CLEAR;
            default : command <= IDLE;
        endcase
    end

endmodule