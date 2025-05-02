`timescale 1ns / 1ps

module FndController_Periph (
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

    logic        fcr;
    logic [13:0] fdr;
    logic [ 3:0] fpr;

    APB_SlaveIntf_FndController U_APB_IntfO (.*);
    FndController U_FND (.*);
endmodule

module APB_SlaveIntf_FndController (
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
    output logic [13:0] fdr,
    output logic [ 3:0] fpr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg3;

    assign fcr = slv_reg0[0];
    assign fdr = slv_reg1[13:0];
    assign fpr = slv_reg2[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule

module FndController (
    input logic PCLK,
    input logic PRESET,
    input logic fcr,
    input logic [13:0] fdr,
    input logic [3:0] fpr,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
);

    logic o_clk;
    logic [3:0] digit1000, digit100, digit10, digit1;
    logic [27:0] blink_data;

    parameter LEFT = 16_000, RIGHT = 16_001, BOTH = 16_002;

    clock_divider #(
        .FCOUNT(100_000)
    ) U_1khz (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(o_clk)
    );

    digit_spliter U_digit_Spliter (
        .bcd(fdr),
        .digit1000(digit1000),
        .digit100(digit100),
        .digit10(digit10),
        .digit1(digit1)
    );

    function [6:0] bcd2seg(input [3:0] bcd);
        begin
            case (bcd)
                4'h0: bcd2seg = 7'h40;
                4'h1: bcd2seg = 7'h79;
                4'h2: bcd2seg = 7'h24;
                4'h3: bcd2seg = 7'h30;
                4'h4: bcd2seg = 7'h19;
                4'h5: bcd2seg = 7'h12;
                4'h6: bcd2seg = 7'h02;
                4'h7: bcd2seg = 7'h78;
                4'h8: bcd2seg = 7'h00;
                4'h9: bcd2seg = 7'h10;
                default: bcd2seg = 7'h7F;
            endcase
        end
    endfunction

    function [27:0] blink(input [13:0] bcd);
        begin
            case (bcd)
                LEFT: blink = {7'b0000110, 7'h3F, 7'h7F, 7'h7F};
                RIGHT: blink = {7'h7F, 7'h7F, 7'h3F, 7'b0110000};
                BOTH: blink = {7'b0000110, 7'h3F, 7'h3F, 7'b0110000};
                default: blink = {7'h7F, 7'h7F, 7'h7F, 7'h7F};
            endcase
        end
    endfunction

    always_ff @(posedge o_clk or posedge PRESET) begin
        if (PRESET) begin
            fndCom  = 4'b1110;
            fndFont = 8'hC0;
        end
        else begin
            if ( (fdr < 10000 ) && fcr) begin
                case (fndCom)
                    4'b0111: begin
                        fndCom  <= 4'b1110;
                        fndFont <= {~fpr[0], bcd2seg(digit1)};
                    end
                    4'b1110: begin
                        fndCom  <= 4'b1101;
                        fndFont <= {~fpr[1], bcd2seg(digit10)};
                    end
                    4'b1101: begin
                        fndCom  <= 4'b1011;
                        fndFont <= {~fpr[2], bcd2seg(digit100)};
                    end
                    4'b1011: begin
                        fndCom  <= 4'b0111;
                        fndFont <= {~fpr[3], bcd2seg(digit1000)};
                    end
                    default: begin
                        fndCom  <= 4'b1110;
                        fndFont <= 8'hC0;
                    end
                endcase
            end
            else if ( (fdr >= 10000) && fcr ) begin
                blink_data = blink(fdr);
                case (fndCom)
                    4'b0111: begin
                        fndCom  <= 4'b1110;
                        fndFont <= {1'b1, blink_data[6:0]};
                    end
                    4'b1110: begin
                        fndCom  <= 4'b1101;
                        fndFont <= {1'b1, blink_data[13:7]};
                    end
                    4'b1101: begin
                        fndCom  <= 4'b1011;
                        fndFont <= {1'b1, blink_data[20:14]};
                    end
                    4'b1011: begin
                        fndCom  <= 4'b0111;
                        fndFont <= {1'b1, blink_data[27:21]};
                    end
                    default: begin
                        fndCom  <= 4'b1110;
                        fndFont <= 8'hC0;
                    end
                endcase
            end
            else if (!fcr) begin
                fndCom <= 4'b1111;
                fndFont <= 8'hFF;
            end
        end
    end

endmodule

module clock_divider #(
    parameter FCOUNT = 100_000
)(
    input logic clk,
    input logic rst,
    output logic o_clk
);
    logic [$clog2(FCOUNT)-1:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            o_clk <= 0;
        end
        else begin
            if (count == FCOUNT - 1) begin
                o_clk <= 1;
                count <= 0;
            end
            else begin
                count <= count + 1;
                o_clk <= 0;
            end
        end
    end
endmodule


module digit_spliter #(
    parameter WIDTH = 14
) (
    input [WIDTH-1:0] bcd,
    output [3:0] digit1000,
    output [3:0] digit100,
    output [3:0] digit10,
    output [3:0] digit1
);

    assign digit1 = (bcd % 10);
    assign digit10 = (bcd % 100) / 10;
    assign digit100 = (bcd % 1000) / 100;
    assign digit1000 = bcd / 1000;

endmodule
