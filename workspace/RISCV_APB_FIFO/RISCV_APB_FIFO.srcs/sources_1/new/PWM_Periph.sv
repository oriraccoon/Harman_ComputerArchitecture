`timescale 1ns / 1ps

module blink_Periph (
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
    output logic        led
);

    logic [$clog2(400)-1:0] bdr;

    APB_SlaveIntf_blink U_APB_IntfO_blink (.*);
    blink_led_IP U_blink_led_IP (.*);


endmodule

module APB_SlaveIntf_blink (
    // global signal
    input  logic                   PCLK,
    input  logic                   PRESET,
    // APB Interface Signals
    input  logic [            3:0] PADDR,
    input  logic [           31:0] PWDATA,
    input  logic                   PWRITE,
    input  logic                   PENABLE,
    input  logic                   PSEL,
    output logic [           31:0] PRDATA,
    output logic                   PREADY,
    // internal signals
    output  logic [$clog2(400)-1:0] bdr
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2, slv_reg3;

    assign bdr = slv_reg0[$clog2(400)-1:0];
    // assign pdr = slv_reg1[7:0];

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

module blink_led_IP (
    input logic PCLK,
    input logic PRESET,
    input logic [$clog2(400)-1:0] bdr,
    output logic led
);

    parameter SYS_CLK = 100_000_000;
    parameter BASE_CLK = 1000;
    parameter ON_TIME = 200;
    logic [$clog2(4000)-1:0] DUTY = bdr * 10;
    logic c_clk;

    clock_divider #(
        .FCOUNT(SYS_CLK / BASE_CLK)
    ) U_divider (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(c_clk)
    );

    typedef enum logic [1:0] {
        STATE_ON,
        STATE_OFF
    } state_t;

    state_t state;
    logic [15:0] counter;

    always_ff @(posedge c_clk or posedge PRESET) begin
        if (PRESET) begin
            state <= STATE_ON;
            counter <= 0;
            led <= 1;
        end
        else begin
            case (state)
                STATE_ON: begin
                    if (counter >= ON_TIME) begin
                        counter <= 0;
                        if (DUTY <= 30) begin
                            state <= STATE_ON;
                            led <= 1;
                        end
                        else begin
                            state <= STATE_OFF;
                            led <= 0;
                        end
                    end
                    else begin
                        counter <= counter + 1;
                        led <= 1;
                    end
                end

                STATE_OFF: begin
                    if (counter >= DUTY) begin
                        counter <= 0;
                        state <= STATE_ON;
                        led <= 1;
                    end
                    else begin
                        counter <= counter + 1;
                        led <= 0;
                    end
                end

                default: begin
                    state <= STATE_ON;
                    counter <= 0;
                    led <= 1;
                end
            endcase
        end
    end

endmodule
