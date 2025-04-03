`timescale 1ns / 1ps

module stopwatch_fnd (
    input         clk,
    input         rst,
    input [$clog2(100):0] ms_count,
    input [$clog2(60):0] s_count,
    input [$clog2(60):0] m_count,
    input  [ 3:0] fndDot,
    output [ 3:0] fndCom,
    output [ 7:0] fndFont
);

    wire tick, fndDp;
    wire [1:0] digit_sel;
    wire [3:0] digit_1, digit_10, digit_100, digit_1000, digit;
    wire [7:0] fndSegData;

    assign fndFont = {fndDp, fndSegData[6:0]};

    sclk_div_1khz U_Clk_Div_1Khz (
        .clk  (clk),
        .rst(rst),
        .tick (tick)
    );

    scounter_2bit U_Conter_2big (
        .clk  (clk),
        .rst(rst),
        .tick (tick),
        .count(digit_sel)
    );

    sdecoder_2x4 U_Dec_2x4 (
        .x(digit_sel),
        .y(fndCom)
    );

    sdigitSplitter U_Digit_Splitter (
        .ms_count   (ms_count),
        .s_count   (s_count),
        .m_count   (m_count),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000)
    );

    smux_4x1 U_Mux_4x1 (
        .sel(digit_sel),
        .x0 (digit_1),
        .x1 (digit_10),
        .x2 (digit_100),
        .x3 (digit_1000),
        .y  (digit)
    );

    sBCDtoSEG_decoder U_BCDtoSEG (
        .bcd(digit),
        .seg(fndSegData)
    );

    smux_4x1_1bit U_Mux_4x1_1bit (
        .sel(digit_sel),
        .x  (fndDot),
        .y  (fndDp)
    );
endmodule

module smux_4x1_1bit (
    input      [1:0] sel,
    input      [3:0] x,
    output reg       y
);

    always @(*) begin
        y = 1'b1;
        case (sel)
            2'b00: y = x[0];
            2'b01: y = x[1];
            2'b10: y = x[2];
            2'b11: y = x[3];
        endcase
    end
endmodule

module sclk_div_1khz (
    input clk,
    input rst,
    output reg tick
);
    reg [$clog2(100_000)-1 : 0] div_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (div_counter == 100_000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule

module scounter_2bit (
    input            clk,
    input            rst,
    input            tick,
    output reg [1:0] count
);
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
        end else begin
            if (tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module sdecoder_2x4 (
    input      [1:0] x,
    output reg [3:0] y
);
    always @(*) begin
        y = 4'b1111;
        case (x)
            2'b00: y = 4'b1110;
            2'b01: y = 4'b1101;
            2'b10: y = 4'b1011;
            2'b11: y = 4'b0111;
        endcase
    end
endmodule

module sdigitSplitter (
    input [$clog2(100):0] ms_count,
    input [$clog2(60):0] s_count,
    input [$clog2(60):0] m_count,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);
    assign digit_1    = ms_count / 10 % 10;
    assign digit_10   = s_count % 10;
    assign digit_100  = s_count / 10 % 10;
    assign digit_1000 = m_count % 10;
endmodule

module smux_4x1 (
    input      [1:0] sel,
    input      [3:0] x0,
    input      [3:0] x1,
    input      [3:0] x2,
    input      [3:0] x3,
    output reg [3:0] y
);
    always @(*) begin
        y = 4'b0000;
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end
endmodule

module sBCDtoSEG_decoder (
    input      [3:0] bcd,
    output reg [7:0] seg
);
    always @(bcd) begin
        case (bcd)
            4'h0: seg = 8'hc0;
            4'h1: seg = 8'hf9;
            4'h2: seg = 8'ha4;
            4'h3: seg = 8'hb0;
            4'h4: seg = 8'h99;
            4'h5: seg = 8'h92;
            4'h6: seg = 8'h82;
            4'h7: seg = 8'hf8;
            4'h8: seg = 8'h80;
            4'h9: seg = 8'h90;
            4'ha: seg = 8'h88;
            4'hb: seg = 8'h83;
            4'hc: seg = 8'hc6;
            4'hd: seg = 8'ha1;
            4'he: seg = 8'h86;
            4'hf: seg = 8'h8e;
            default: seg = 8'hff;
        endcase
    end
endmodule
