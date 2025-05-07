`timescale 1ns / 1ps

module Timer_Periph (
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
    output logic        PREADY
);

    logic [31:0] tcnr;
    logic [1:0] tcr;
    logic [31:0] psc;
    logic [31:0] arr;

    APB_SlaveIntf_Timer U_APB_IntfO_Timer (.*);
    Timer U_Timer (.*);
endmodule

module APB_SlaveIntf_Timer (
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
    input  logic [31:0] tcnr,
    output logic [1:0] tcr,
    output logic [31:0] psc,
    output logic [31:0] arr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign slv_reg0[31:0] = tcnr;
    assign tcr[1:0] = slv_reg1[1:0];
    assign psc = slv_reg2;
    assign arr = slv_reg3;
    // assign tcr = slv_reg3[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            // slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        // 2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
                        2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule

module Timer (
    input logic PCLK,
    input logic PRESET,
    output logic [31:0] tcnr,
    input logic [1:0] tcr,
    input logic [31:0] psc,
    input logic [31:0] arr
);

    parameter SYS_CLK = 100_000_000, NEED_HZ = 1_000;
    logic o_clk;

    prescaler U_psc (.*);

    always_ff @(posedge o_clk or posedge PRESET) begin
        if (PRESET) begin
            tcnr <= 0;
        end else begin
            if (tcr[0]) begin
                if (tcnr == arr) begin
                    tcnr <= 0;
                end
                else tcnr <= tcnr + 1;
            end
            if (tcr[1]) tcnr <= 0;
        end
    end


endmodule

module prescaler (
    input logic PCLK,
    input logic PRESET,
    input logic [31:0] psc,
    output logic o_clk
);

    logic [31:0] count;

    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            count <= 0;
            o_clk <= 0;
        end else begin
            if (count == psc) begin
                o_clk <= 1;
                count <= 0;
            end else begin
                count <= count + 1;
                o_clk <= 0;
            end
        end
    end
endmodule
