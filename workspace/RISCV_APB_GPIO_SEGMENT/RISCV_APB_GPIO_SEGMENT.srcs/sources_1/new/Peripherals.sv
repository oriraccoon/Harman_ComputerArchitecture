`timescale 1ns / 1ps

module Ultrasonic_Periph (
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
    input  logic        echo,
    output logic        trig
);

    logic                   ucr;
    logic [$clog2(400)-1:0] udr;

    APB_SlaveIntf_Ultrasonic U_APB_IntfO_Ultrasonic (.*);
    Ultrasonic_IP U_Ultrasonic (.*);

endmodule

module APB_SlaveIntf_Ultrasonic (
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
    input  logic [$clog2(400)-1:0] udr,
    output logic                   ucr
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2, slv_reg3;

    assign ucr = slv_reg0[0];
    assign slv_reg1[$clog2(400)-1:0] = udr;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            // slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        // 2'd1: slv_reg1 <= PWDATA;
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

module Ultrasonic_IP (
    input  logic                   PCLK,
    input  logic                   PRESET,
    input  logic                   ucr,
    output logic [$clog2(400)-1:0] udr,
    input  logic                   echo,
    output logic                   trig
);

    typedef enum {
        IDLE,
        START,
        HIGH_COUNT,
        DIST
    } state_e;

    state_e state, next;
    logic [$clog2(10_000_000)-1:0] sec_reg;
    logic prev_echo, sync_prev_echo;
    logic [$clog2(1000)-1:0] PCLK_count, PCLK_count_next;
    logic trig_reg, trig_next;
    logic [$clog2(23200)-1:0] dist_reg, dist_next;
    logic [$clog2(400)-1:0] centi_reg, centi_next;
    logic o_PCLK;

    assign udr = centi_reg;  // input

    clock_divider #(
        .FCOUNT(50_000_000)
    ) U_0_5sec (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(o_PCLK)
    );

    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            state <= IDLE;
            prev_echo <= 0;
            PCLK_count <= 0;
            trig_reg <= 0;
            dist_reg <= 0;
            centi_reg <= 0;
        end else begin
            state <= next;
            prev_echo <= sync_prev_echo;
            PCLK_count <= PCLK_count_next;
            trig_reg <= trig_next;
            dist_reg <= dist_next;
            centi_reg <= centi_next;
        end
    end


    assign trig = trig_reg;

    always @(*) begin
        next = state;
        sync_prev_echo = prev_echo;
        PCLK_count_next = PCLK_count;
        trig_next = trig_reg;
        dist_next = dist_reg;
        centi_next = centi_reg;
        case (state)
            IDLE: begin
                if (ucr) begin
                    next = START;
                end
            end
            START: begin
                PCLK_count_next = PCLK_count + 1;
                trig_next = 1;
                if (PCLK_count == 1000) begin
                    trig_next = 0;
                    next = HIGH_COUNT;
                    PCLK_count_next = 0;
                end
            end
            HIGH_COUNT: begin
                if (~prev_echo & echo) begin
                    dist_next = 0;
                end else if (prev_echo & echo) begin
                    PCLK_count_next = PCLK_count + 1;
                    if (PCLK_count == 100) begin
                        dist_next = dist_reg + 1;
                        PCLK_count_next = 0;
                    end
                end else if (prev_echo & ~echo) begin
                    next = DIST;
                end else begin
                    if (o_PCLK) begin
                        dist_next = 0;
                        next = DIST;
                    end
                end
            end
            DIST: begin
                centi_next = dist_reg / 58;
                next = IDLE;
            end
        endcase

        sync_prev_echo = echo;

    end

endmodule
