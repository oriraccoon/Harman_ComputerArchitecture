`timescale 1ns / 1ps

module Stopwatch_Periph (
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
    // inport signals
    output logic [ 3:0] fndCom,
    output logic [ 7:0] fndFont
);

    logic       fcr;
    logic [13:0] fdr;

    APB_SlaveIntf_FndDontroller U_APB_IntfO (.*);
    FndController U_FND (.*);
endmodule

module APB_SlaveIntf_Stopwatch (
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
    // internal signals
    output logic        fcr,
    output logic [13:0] fdr
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2, slv_reg3;

    assign fcr = slv_reg0[0];
    assign fdr = slv_reg1[13:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        // 2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module Stopwatch_IP (
    input logic PCLK,
    input logic PRESET,
    input logic fcr,
    input logic [13:0] fdr,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
);

    logic o_clk;
    logic [3:0] digit1000, digit100, digit10, digit1;

    clock_divider #(
        .FCOUNT(100_000)
    ) U_1khz (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(o_clk)
    );

    digit_spliter U_digit_Spliter(
        .bcd(fdr),
        .digit1000(digit1000),
        .digit100(digit100),
        .digit10(digit10),
        .digit1(digit1)
    );

    function [6:0] bcd2seg(
        input [3:0]bcd 
    );
        begin
            case (bcd)
                4'h0:  bcd2seg = 7'h40;
                4'h1:  bcd2seg = 7'h79;
                4'h2:  bcd2seg = 7'h24;
                4'h3:  bcd2seg = 7'h30;
                4'h4:  bcd2seg = 7'h19;
                4'h5:  bcd2seg = 7'h12;
                4'h6:  bcd2seg = 7'h02;
                4'h7:  bcd2seg = 7'h78;
                4'h8:  bcd2seg = 7'h00;
                4'h9:  bcd2seg = 7'h10;
                default: bcd2seg = 7'h7F;
            endcase
        end
    endfunction

    initial begin
        fndCom = 4'b1110;
        fndFont = 8'hFF;
    end

    always_ff @( posedge o_clk ) begin
        if (fcr) begin
            case (fndCom)
                4'b0111: begin
                    fndCom <= 4'b1110;
                    fndFont <= {1'b1,bcd2seg(digit1)};
                end
                4'b1110: begin
                    fndCom <= 4'b1101;
                    fndFont <= {1'b1,bcd2seg(digit10)};
                end
                4'b1101: begin
                    fndCom <= 4'b1011;
                    fndFont <= {1'b0,bcd2seg(digit100)};
                end
                4'b1011: begin
                    fndCom <= 4'b0111;
                    fndFont <= {1'b1,bcd2seg(digit1000)};
                end
                default: begin
                    fndCom <= 4'b1110;
                    fndFont <= 8'hFF;
                end
            endcase
        end
    end

endmodule
