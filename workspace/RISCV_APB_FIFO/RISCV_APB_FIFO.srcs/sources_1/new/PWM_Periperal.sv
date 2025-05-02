`timescale 1ns / 1ps

module PWM_Periperal(
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

    output logic [1:0] light
);

    logic [7:0] pdr;

    APB_SlaveIntf_PWM U_APB_IntfO_PWM (.*);
    PWM_IP U_PWM_IP (.*,
    .clk(PCLK),
    .reset(PRESET));

endmodule

module APB_SlaveIntf_PWM (
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
    output logic [7:0] pdr
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2, slv_reg3;

    assign pdr = slv_reg1[0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            // slv_reg0 <= 0;
            slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        //    2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        // 2'd1: PRDATA <= slv_reg1;
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

module PWM_IP (
    input logic clk,
    input logic reset,
    input logic [7:0] pdr,
    output logic [1:0] light
);

    parameter SYS_CLK = 100_000_000, PWM_FREQ = 1000, PWM_COUNTER_MAX = 255;

    logic c_clk;

    clock_divider_pwm #(
        .FCOUNT(SYS_CLK / PWM_FREQ)
    ) U_divider (
        .clk  (clk),
        .rst  (reset),
        .o_clk(c_clk)
    );

    logic [7:0] counter;

    always_ff @(posedge c_clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end

    always_comb begin
        if (pdr == 0) begin
            light = 0;
        end
        else if (counter < pdr) begin
            light = 2'b11;
        end
        else begin
            light = 0;
        end
    end

endmodule


module clock_divider_pwm #(
    parameter FCOUNT = 100_000
)(
    input logic clk,
    input logic rst,
    output logic o_clk
);
    logic [$clog2(FCOUNT/2)-1:0] count;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            o_clk <= 0;
        end
        else begin
            if (count == FCOUNT/2 - 1) begin
                o_clk <= ~o_clk;
                count <= 0;
            end
            else begin
                count <= count + 1;
            end
        end
    end
endmodule

