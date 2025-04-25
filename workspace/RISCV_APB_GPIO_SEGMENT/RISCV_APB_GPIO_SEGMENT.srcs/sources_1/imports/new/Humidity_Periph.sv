module Humidity_Periph (
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

    inout logic dht_io
);

    logic [15:0] ddr;
    logic dmr;

    APB_SlaveIntf_Humidity U_APB_IntfO_Humidity (.*);
    Humidity_IP U_Humidity (.*);

endmodule

module APB_SlaveIntf_Humidity (
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
    input  logic [15:0] ddr,
    output logic dmr
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2, slv_reg3;

    assign slv_reg0[15:0] = ddr;
    assign dmr = slv_reg1[0];

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

module Humidity_IP (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic        dmr,
    output logic [15:0] ddr,

    inout dht_io
);

    parameter START_CNT = 18000, WAIT_CNT = 30, DATA_0 = 40, TIME_OUT = 20000;

    typedef enum {
        IDLE = 3'b000,
        START,
        WAIT,
        RESPONSE,
        READY,
        SET,
        READ
    } state_e;

    state_e state, next;
    logic tick;
    logic o_clk;
    logic [$clog2(TIME_OUT)-1:0] tick_count_reg, tick_count_next;
    logic dht_io_reg, dht_io_next;
    logic dht_io_oe_reg, dht_io_oe_next;
    logic [4:0] sec_reg, sec_next;
    logic [39:0] data_buffer, data_buffer_next;
    logic [5:0] bit_count, bit_count_next;
    logic dht_io_sync;
    logic [15:0] humidity_reg, humidity_next, temperature_reg, temperature_next;
    logic [15:0] humidity_data;
    logic [15:0] temperature_data;

    assign dht_io = (dht_io_oe_reg) ? dht_io_reg : 1'bz;
    assign ddr = dmr ? humidity_data : temperature_data;

    clock_divider #(
        .FCOUNT(50_000_000)
    ) U_0_5sec (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(o_clk)
    );

    clock_divider #(
        .FCOUNT(100)
    ) U_tick_gen (
        .clk  (PCLK),
        .rst  (PRESET),
        .o_clk(tick)
    );


    always @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            state <= IDLE;
            dht_io_reg <= 0;
            tick_count_reg <= 0;
            dht_io_oe_reg <= 1;
            data_buffer <= 0;
            bit_count <= 0;
            humidity_reg <= 0;
            temperature_reg <= 0;
            dht_io_sync <= 0;
            sec_reg <= 0;
        end else begin
            state <= next;
            dht_io_reg <= dht_io_next;
            tick_count_reg <= tick_count_next;
            dht_io_oe_reg <= dht_io_oe_next;
            data_buffer <= data_buffer_next;
            bit_count <= bit_count_next;
            sec_reg <= sec_next;
            dht_io_sync <= dht_io;
            humidity_reg <= humidity_next;
            humidity_data <= humidity_reg;
            temperature_reg <= temperature_next;
            temperature_data <= temperature_reg;
        end
    end



    always @(*) begin
        next = state;
        dht_io_next = dht_io_reg;
        tick_count_next = tick_count_reg;
        dht_io_oe_next = dht_io_oe_reg;
        data_buffer_next = data_buffer;
        bit_count_next = bit_count;
        sec_next = sec_reg;
        humidity_next = humidity_reg;
        temperature_next = temperature_reg;

        case (state)
            IDLE: begin
                dht_io_oe_next = 1;
                dht_io_next = 1;
                if (o_clk) sec_next = sec_next + 1;
                else if (sec_reg == 20) begin
                    next = START;
                    sec_next = 0;
                    tick_count_next = 0;
                    data_buffer_next = 0;
                end
            end

            START: begin
                dht_io_next = 0;
                if (tick) begin
                    if (tick_count_reg == START_CNT) begin
                        next = WAIT;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            WAIT: begin
                dht_io_next = 1;
                if (tick) begin
                    if (tick_count_reg == WAIT_CNT) begin
                        next = RESPONSE;
                        tick_count_next = 0;
                        dht_io_oe_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            RESPONSE: begin
                if (tick) begin
                    if (tick_count_reg >= 20) begin
                        if (dht_io) begin
                            next = READY;
                            tick_count_next = 0;
                        end
                    end else tick_count_next = tick_count_reg + 1;
                end
            end

            READY: begin
                if (tick) begin
                    if (tick_count_reg >= 30) begin
                        if (~dht_io) begin
                            next = SET;
                            bit_count_next = 0;
                            tick_count_next = 0;
                        end
                    end else tick_count_next = tick_count_reg + 1;
                end
            end

            SET: begin
                if (tick) begin
                    if (tick_count_reg >= 15) begin
                        if (bit_count == 40) begin
                            bit_count_next = 0;
                            if (data_buffer[7:0] == (data_buffer[39:32] + data_buffer[31:24] + data_buffer[23:16] + data_buffer[15:8])) begin
                                humidity_next = {
                                    data_buffer[31:24], data_buffer[39:32]
                                };
                                temperature_next = {
                                    data_buffer[15:8], data_buffer[23:16]
                                };
                            end else begin
                                humidity_next = 16'd404;
                                temperature_next = 16'd404;
                            end
                            next = IDLE;
                            tick_count_next = 0;
                        end else if (dht_io) begin
                            next = READ;
                            tick_count_next = 0;
                        end
                    end else tick_count_next = tick_count_reg + 1;
                end
            end

            READ: begin
                if (tick) begin
                    if (~dht_io) begin

                        data_buffer_next = {
                            data_buffer[38:0], (tick_count_reg > DATA_0)
                        };
                        bit_count_next = bit_count + 1;
                        tick_count_next = 0;
                        next = SET;

                    end else if (dht_io) begin
                        tick_count_next = tick_count_reg + 1;
                        if (tick_count_reg == TIME_OUT - 1) begin
                            next = IDLE;
                        end
                    end

                end
            end
        endcase
    end

endmodule
