`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        rst,
    input        mode_btn,      //change
    input        run_stop_btn,  //en
    input        clear_btn,     //clear
    input        up_down_btn,   //mode
    output [3:0] fndCom,
    output [7:0] fndFont,
    output       tx,
    input        rx
);

    wire [13:0] ud_fndData;
    wire [ 3:0] ud_fndDot, sw_fndDot;
    wire ud_en, ud_clear, ud_mode, sw_en, sw_clear;
    wire change;
    wire b_en, b_clear, b_mode, b_change;

    wire [3:0] ud_fndCom, sw_fndCom;
    wire [7:0] ud_fndFont, sw_fndFont;

    wire [7:0] rx_data;
    wire       rx_done;
    wire [7:0] tx_data;
    wire       tx_start;
    wire       tx_busy;
    wire       tx_done;
   
    wire [$clog2(100):0] ms_count;
    wire [$clog2(60):0] s_count;
    wire [$clog2(60):0] m_count;

    btn_edge_trigger U_btn_run(
                        .clk(clk),
                        .rst(rst),
                        .i_btn(run_stop_btn),
                        .o_btn(b_en)
    );
    btn_edge_trigger U_btn_clear(
                        .clk(clk),
                        .rst(rst),
                        .i_btn(clear_btn),
                        .o_btn(b_clear)
    );
    btn_edge_trigger U_btn_mode(
                        .clk(clk),
                        .rst(rst),
                        .i_btn(mode_btn),
                        .o_btn(b_mode)
    );
    btn_edge_trigger U_btn_ud(
                        .clk(clk),
                        .rst(rst),
                        .i_btn(up_down_btn),
                        .o_btn(b_change)
    );

    uart U_uart (
        // global port
        .clk(clk),
        .rst(rst),
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
        .rst     (rst),
        // btn signal
        .b_en(b_en),
        .b_clear(b_clear),
        .b_mode(b_mode),
        .b_change(b_change),
        // tx side port
        .tx_data (tx_data),
        .tx_start(tx_start),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        // rx side port
        .rx_data (rx_data),
        .rx_done (rx_done),
        // data path side port
        .ud_en      (ud_en),
        .ud_clear   (ud_clear),
        .ud_mode    (ud_mode),
        .sw_en      (sw_en),
        .sw_clear   (sw_clear),
        .change (change)
    );

    counter_up_down U_Counter (
        .clk     (clk),
        .rst     (rst),
        .en      (ud_en),
        .clear   (ud_clear),
        .mode    (ud_mode),
        .count   (ud_fndData),
        .dot_data(ud_fndDot)
    );

    stopwatch U_stopwatch(
        .clk     (clk),
        .rst     (rst),
        .en      (sw_en),
        .clear   (sw_clear),
        .ms_count   (ms_count),
        .s_count   (s_count),
        .m_count   (m_count),
        .dot_data(sw_fndDot)
    );

    stopwatch_fnd U_stopwatch_fnd(
        .clk    (clk),
        .rst    (rst),
        .ms_count   (ms_count),
        .s_count   (s_count),
        .m_count   (m_count),
        .fndDot (sw_fndDot),
        .fndCom (sw_fndCom),
        .fndFont(sw_fndFont)
    );

    fndController U_FndController (
        .clk    (clk),
        .rst    (rst),
        .fndData(ud_fndData),
        .fndDot (ud_fndDot),
        .fndCom (ud_fndCom),
        .fndFont(ud_fndFont)
    );

    mux_1x4x8 u_mux148(
        .sel(change),
        .x0(ud_fndCom),
        .x1(ud_fndFont),
        .x2(sw_fndCom),
        .x3(sw_fndFont),
        .y0(fndCom),
        .y1(fndFont)
    );

endmodule

module mux_1x4x8 (
    input      sel,
    input      [3:0] x0,
    input      [7:0] x1,
    input      [3:0] x2,
    input      [7:0] x3,
    output reg [3:0] y0,
    output reg [7:0] y1
);
    always @(*) begin
        case (sel)
            1'b0: begin
                y0 = x0;
                y1 = x1;
            end
            1'b1: begin
                y0 = x2;
                y1 = x3;
            end
        endcase
    end
endmodule

module control_unit (
    input            clk,
    input            rst,
    // btn signal
    input           b_en,
    input           b_clear,
    input           b_mode,
    input           b_change,
    // tx side port
    output reg [7:0] tx_data,
    output reg       tx_start,
    input            tx_busy,
    input            tx_done,
    // rx side port
    input      [7:0] rx_data,
    input            rx_done,
    // data path side port
    output reg       ud_en,
    output reg       ud_clear,
    output reg       ud_mode,
    output reg       sw_en,
    output reg       sw_clear,
    output reg          change

);
    localparam STOP = 0, RUN = 1, CLEAR = 2;
    localparam UP = 0, DOWN = 1;
    localparam IDLE = 0, ECHO = 1;
    localparam UD = 0, SW = 1;

    reg [1:0] state, state_next, s_state, s_state_next;
    reg mode_state, mode_state_next;
    reg echo_state, echo_state_next;
    reg change_state, change_state_next;
    reg en, clear, mode, s_en, s_clear;

    reg ud_en_next, ud_clear_next, ud_mode_next, sw_en_next, sw_clear_next, sw_mode_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state      <= STOP;
            s_state      <= STOP;
            mode_state <= UP;
            echo_state <= IDLE;
            change_state <= UD;
            ud_en <= 0;
            ud_clear <= 0;
            ud_mode <= 0;
            sw_en <= 0;
            sw_clear <= 0;
        end else begin
            state      <= state_next;
            s_state      <= s_state_next;
            mode_state <= mode_state_next;
            echo_state <= echo_state_next;
            change_state <= change_state_next;
            ud_en <= ud_en_next;
            ud_clear <= ud_clear_next;
            ud_mode <= ud_mode_next;
            sw_en <= sw_en_next;
            sw_clear <= sw_clear_next;
        end
    end

    always @(*) begin
        change_state_next = change_state;
        change = 0;
        ud_en_next = ud_en;
        ud_clear_next = ud_clear;
        ud_mode_next = ud_mode;
        sw_en_next = sw_en;
        sw_clear_next = sw_clear;
        case (change_state)
            UD: begin
                change = 0;
                ud_en_next = en;
                ud_clear_next = clear;
                ud_mode_next = mode;
                if(rx_done) begin
                    if(rx_data == "h" || rx_data == "H") begin
                        change_state_next = SW;
                    end
                end else if(b_change) begin
                    change_state_next = SW;
                end
            end
            SW: begin
                change = 1;
                sw_en_next = s_en;
                sw_clear_next = s_clear;
                if(rx_done) begin
                    if(rx_data == "h" || rx_data == "H") begin
                        change_state_next = UD;
                    end
                end else if(b_change) begin
                    change_state_next = UD;
                end
            end
        endcase
            
        
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
        if(~change) begin
            case (mode_state)
                UP: begin
                    mode = 1'b0;
                    if (rx_done) begin
                        if (rx_data == 8'h4d || rx_data == 8'h6d)
                            mode_state_next = DOWN;  // ASCII 'M', 'm'
                    end else if(b_mode) begin
                        mode_state_next = DOWN;
                end
                end
                DOWN: begin
                    mode = 1'b1;
                    if (rx_done) begin
                        if (rx_data == 8'h4d || rx_data == 8'h6d)
                            mode_state_next = UP;  // ASCII 'M', 'm'
                    end else if(b_mode) begin
                        mode_state_next = UP;
                end
                end
            endcase
        end
    end

    always @(*) begin
        state_next = state;
        en         = 1'b0;
        clear      = 1'b0;
        if(~change) begin
            case (state)
                STOP: begin
                    en = 1'b0;
                    clear = 1'b0;
                    if (rx_done) begin
                        if (rx_data == 8'h72 || rx_data == 8'h52)
                            state_next = RUN;  // ASCII 'r', 'R'
                        else if (rx_data == 8'h63 || rx_data == 8'h43)
                            state_next = CLEAR;  // ASCII 'c', 'C'
                    end else if(b_en) begin
                        state_next = RUN;
                    end else if(b_clear) begin
                        state_next = CLEAR;
                    end
                end
                RUN: begin
                    en = 1'b1;
                    clear = 1'b0;
                    if (rx_done) begin
                        if (rx_data == 8'h72 || rx_data == 8'h52)
                            state_next = STOP;
                        else if (rx_data == 8'h63 || rx_data == 8'h43)
                            state_next = CLEAR;  // ASCII 'c', 'C'
                    end else if(b_en) begin
                        state_next = STOP;
                    end else if(b_clear) begin
                        state_next = CLEAR;
                    end
                end
                CLEAR: begin
                    en = 1'b0;
                    clear = 1'b1;
                    state_next = STOP;
                end
            endcase
        end
    end

    always @(*) begin
        s_state_next = s_state;
        s_en         = 1'b0;
        s_clear      = 1'b0;
        if(change) begin
            case (s_state)
                STOP: begin
                    s_en = 1'b0;
                    s_clear = 1'b0;
                    if (rx_done) begin
                        if (rx_data == 8'h72 || rx_data == 8'h52)
                            s_state_next = RUN;  // ASCII 'r', 'R'
                        else if (rx_data == 8'h63 || rx_data == 8'h43)
                            s_state_next = CLEAR;  // ASCII 'c', 'C'
                    end else if(b_en) begin
                        s_state_next = RUN;
                    end else if(b_clear) begin
                        s_state_next = CLEAR;
                    end
                end
                RUN: begin
                    s_en = 1'b1;
                    s_clear = 1'b0;
                    if (rx_done) begin
                        if (rx_data == 8'h72 || rx_data == 8'h52)
                            s_state_next = STOP;
                        else if (rx_data == 8'h63 || rx_data == 8'h43)
                            s_state_next = CLEAR;  // ASCII 'c', 'C'
                    end else if(b_en) begin
                        s_state_next = STOP;
                    end else if(b_clear) begin
                        s_state_next = CLEAR;
                    end
                end
                CLEAR: begin
                    s_en = 1'b0;
                    s_clear = 1'b1;
                    s_state_next = STOP;
                end
            endcase
        end
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

module comp_2dot (
    input  [7:0] ms_count,
    output [ 3:0] dot_data
);
    assign dot_data = ((ms_count / 10 % 10) < 5) ? 4'b0101 : 4'b1111;

endmodule

module stopwatch (
    input         clk,
    input         rst,
    input         en,
    input         clear,
    output [$clog2(100):0] ms_count,
    output [$clog2(60):0] s_count,
    output [$clog2(60):0] m_count,
    output [ 3:0] dot_data
);
    wire tick;

    sclk_div_10hz U_sClk_Div_10Hz (
        .clk  (clk),
        .rst(rst),
        .tick (tick),
        .en   (en),
        .clear(clear)
    );

    stopwatch_counter U_stopwatch_counter (
        .clk  (clk),
        .rst(rst),
        .tick (tick),
        .en   (en),
        .clear(clear),
        .ms_count(ms_count),
        .s_count(s_count),
        .m_count(m_count)
    );

    comp_2dot U_Comp_2Dot (
        .ms_count(ms_count),
        .dot_data(dot_data)
    );

endmodule

module stopwatch_counter (
    input         clk,
    input         rst,
    input         tick,
    input         en,
    input         clear,
    output [$clog2(100):0] ms_count,
    output [$clog2(60):0] s_count,
    output [$clog2(60):0] m_count
);
    reg [$clog2(100)-1:0] ms_counter;
    reg [$clog2(60)-1:0] s_counter;
    reg [$clog2(60)-1:0] m_counter;

    assign ms_count = ms_counter;
    assign s_count = s_counter;
    assign m_count = m_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            ms_counter <= 0;
            s_counter <= 0;
            m_counter <= 0;
        end else begin
            if (clear) begin
                ms_counter <= 0;
                s_counter <= 0;
                m_counter <= 0;
            end else begin
                if (en) begin
                    if (tick) begin
                        if (ms_counter == 99) begin
                            ms_counter <= 0;
                            if(s_counter == 59) begin
                                s_counter <= 0;
                                if(m_counter == 59) begin
                                    m_counter <= 0;
                                end else m_counter <= m_counter + 1;
                            end else s_counter <= s_counter + 1;
                        end else begin
                            ms_counter <= ms_counter + 1;
                        end
                    end
                end
            end
        end
    end

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

module sclk_div_10hz (
    input  wire clk,
    input  wire rst,
    input  wire en,
    input  wire clear,
    output reg  tick
);
    reg [$clog2(1_000_000)-1:0] div_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (en) begin
                if (div_counter == 1_000_000 - 1) begin
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
