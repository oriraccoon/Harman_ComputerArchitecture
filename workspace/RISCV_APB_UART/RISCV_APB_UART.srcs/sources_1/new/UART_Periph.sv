`timescale 1ns / 1ps

module UART_Periph (
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
    input  logic        rx,
    output logic        tx
);

    logic full;
    logic empty, tx_empty;
    logic [7:0] fwdr_tx, fwdr_rx;
    logic [7:0] frdr_tx, frdr_rx;
    logic [1:0] en;
    logic [7:0] tx_data_in, tx_data, rdata, rx_data;
    logic tx_done, rx_done;

    always @(posedge PCLK or posedge PRESET) begin
        if (PRESET) tx_data_in = 0;
        else begin
            if (!tx_done) tx_data_in = tx_data;
            else tx_data_in = tx_data_in;
        end
    end
    UART_IP U_Uart (
        .clk(PCLK),
        .rst(PRESET),
        // tx
        .btn_start((!tx_empty & ~tx_done)),
        .tx_data(tx_data_in),
        .tx_done(tx_done),
        .tx(tx),
        // rx
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .tick()
    );

    APB_SlaveIntf_FIFO U_APB_IntfO_FIFO_rx (
        .*,
        .fwdr (fwdr_rx),
        .frdr (rx_data),
        .full (full),
        .empty(empty)
    );

    FIFO U_FIFO_rx (
        .clk(PCLK),  //
        .reset(PRESET),  //
        // write side
        .wdata(fwdr_rx),
        .wr_en(en[1]),  //
        .full(full),  //
        // read side
        .rdata(rx_data),  //
        .rd_en(en[0]),  //
        .empty(empty)  //
    );

    FIFO U_FIFO_tx (
        .clk(PCLK),  //
        .reset(PRESET),  // 
        // write side
        .wdata(rdata),  //
        .wr_en(~empty),  //
        .full(full),  //
        // read side
        .rdata(tx_data),  // ?
        .rd_en(~en[0]),  //
        .empty(tx_empty)  // ?
    );

    APB_SlaveIntf_FIFO U_APB_IntfO_FIFO_tx (
        .*,
        .fwdr(fwdr_tx),
        .frdr(frdr_tx),
        .full(full),
        .empty(tx_empty)
    );

    
endmodule







module APB_SlaveIntf_FIFO (
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
    output logic [ 1:0] en,

    input  logic       full,
    input  logic       empty,
    output logic [7:0] fwdr,
    input  logic [7:0] frdr
);

    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg3;
    logic wr_en, rd_en;

    assign slv_reg0[1:0] = {full, empty};
    assign fwdr = slv_reg1[7:0];
    assign slv_reg2[7:0] = frdr;
    assign en = {wr_en, rd_en};

    typedef enum {
        IDLE,
        READ,
        WRITE
    } rw_state_e;

    rw_state_e state, next;

    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            state <= IDLE;
            // slv_reg0 <= 0;
            slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            case (state)
                IDLE: begin
                    wr_en <= 1'b0;
                    rd_en <= 1'b0;
                    if (PSEL && PENABLE) begin
                        PREADY <= 1'b1;
                        if (~empty && ~PWRITE) begin
                            rd_en  <= 1'b1;
                            PRDATA <= 32'bx;
                            case (PADDR[3:2])
                                2'd0: PRDATA <= slv_reg0;
                                2'd1: PRDATA <= slv_reg1;
                                2'd2: PRDATA <= slv_reg2;
                                // 2'd3: PRDATA <= slv_reg3;
                            endcase
                        end else if (~full && PWRITE) begin
                            wr_en <= 1'b1;
                            case (PADDR[3:2])
                                // 2'd0: slv_reg0 <= PWDATA;
                                2'd1: slv_reg1 <= PWDATA;
                                // 2'd2: slv_reg2 <= PWDATA;
                                // 2'd3: slv_reg3 <= PWDATA;
                            endcase
                        end
                    end else PREADY <= 1'b0;
                end
                READ: begin
                    rd_en <= 1'b0;
                end
                WRITE: begin
                    wr_en <= 1'b0;
                end
            endcase
            state <= next;
        end
    end

    always_comb begin
        case (state)
            IDLE: begin
                if (PSEL && PENABLE) begin
                    if (~empty && ~PWRITE) begin
                        next = READ;
                    end else if (~full && PWRITE) begin
                        next = WRITE;
                    end
                end
            end
            READ:  next = IDLE;
            WRITE: next = IDLE;
        endcase
    end

endmodule

module FIFO (
    input  logic       clk,
    input  logic       reset,
    // write side
    input  logic [7:0] wdata,
    input  logic       wr_en,
    output logic       full,
    // read side
    output logic [7:0] rdata,
    input  logic       rd_en,
    output logic       empty
);

    logic [1:0] wr_ptr, rd_ptr;

    fifo_ram U_fifo_ram (
        .*,
        .wAddr(wr_ptr),
        .wr_en(wr_en & ~full),
        .rAddr(rd_ptr)
    );

    fifo_control_unit U_fifo_control_unit (.*);

endmodule


module fifo_ram (
    input  logic       clk,
    input  logic [1:0] wAddr,
    input  logic [7:0] wdata,
    input  logic       wr_en,
    input  logic [1:0] rAddr,
    output logic [7:0] rdata
);

    logic [7:0] mem[0:2**2-1];

    always_ff @(posedge clk) begin
        if (wr_en) begin
            mem[wAddr] = wdata;
        end
    end

    always_comb begin
        rdata = mem[rAddr];
    end

endmodule

module fifo_control_unit (
    input  logic       clk,
    input  logic       reset,
    // write side
    output logic [1:0] wr_ptr,
    input  logic       wr_en,
    output logic       full,
    // read side
    output logic [1:0] rd_ptr,
    input  logic       rd_en,
    output logic       empty
);

    localparam READ = 2'b01, WRITE = 2'b10, READ_WRITE = 2'b11;

    logic [1:0] state;
    logic [1:0] wr_ptr_next, rd_ptr_next;
    logic full_next, empty_next;

    assign state = {wr_en, rd_en};

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
            full   <= 0;
            rd_ptr <= 0;
            empty  <= 0;
        end else begin
            wr_ptr <= wr_ptr_next;
            rd_ptr <= rd_ptr_next;
            full   <= full_next;
            empty  <= empty_next;
        end
    end

    always_comb begin
        wr_ptr_next = wr_ptr;
        rd_ptr_next = rd_ptr;
        full_next   = full;
        empty_next  = empty;
        case (state)
            READ: begin
                if (empty == 1'b0) begin
                    full_next   = 1'b0;
                    rd_ptr_next = rd_ptr + 1;
                    if (rd_ptr_next == wr_ptr) begin
                        empty_next = 1'b1;
                    end
                end
            end
            WRITE: begin
                if (full == 1'b0) begin
                    empty_next  = 1'b0;
                    wr_ptr_next = wr_ptr + 1;
                    if (wr_ptr_next == rd_ptr) begin
                        full_next = 1'b1;
                    end
                end
            end
            READ_WRITE: begin
                if (empty == 1'b1) begin
                    wr_ptr_next = wr_ptr + 1;
                    empty_next  = 1'b0;
                end else if (full == 1'b1) begin
                    rd_ptr_next = rd_ptr + 1;
                    full_next   = 1'b0;
                end else begin
                    wr_ptr_next = wr_ptr + 1;
                    rd_ptr_next = rd_ptr + 1;
                end
            end
            default: begin

            end
        endcase
    end


endmodule

module UART_IP (
    input  logic       clk,
    input  logic       rst,
    // tx
    input  logic       btn_start,
    input  logic [7:0] tx_data,
    output logic       tx_done,
    output logic       tx,
    // rx
    input  logic       rx,
    output logic       rx_done,
    output logic [7:0] rx_data,
    output logic       tick
);

    logic w_tick;

    assign tick = w_tick;



    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .start_trigger(btn_start),
        .data_in(tx_data),
        .o_tx_done(tx_done),
        .o_tx(tx)
    );


    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .tick(w_tick),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    baud_tick_gen U_BAUD_Tick_Gen (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_tick)
    );

endmodule
module uart_tx (
    input  logic       clk,
    input  logic       rst,
    input  logic       tick,
    input  logic       start_trigger,
    input  logic [7:0] data_in,
    output logic       o_tx_done,
    output logic       o_tx
);
    // fsm state
    parameter IDLE = 0, SEND = 1, START = 2, DATA = 3, STOP = 4;

    logic [3:0] state, next;
    logic tx_reg, tx_next;
    logic tx_done_reg, tx_done_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [3:0] tick_count_reg, tick_count_next;
    assign o_tx_done = tx_done_reg;
    assign o_tx = tx_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx_reg <= 1'b1;    //  Uart tx line을 초기에 항상 1로 만들기 위함.
            tx_done_reg <= 0;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
        end else begin
            state          <= next;
            tx_reg         <= tx_next;
            tx_done_reg    <= tx_done_next;
            bit_count_reg  <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    // next
    always @(*) begin
        next            = state;
        tx_next         = tx_reg;
        tx_done_next    = tx_done_reg;
        bit_count_next  = bit_count_reg;
        tick_count_next = tick_count_reg;
        case (state)
            IDLE: begin
                tx_next = 1'b1;
                tx_done_next = 1'b0;
                tick_count_next = 4'h0;
                if (start_trigger) begin
                    next = SEND;
                end
            end
            SEND: begin
                if (tick == 1'b1) begin
                    next = START;
                end
            end
            START: begin
                tx_done_next = 1'b1;  //
                tx_next      = 1'b0;  // 출력을 0으로 유지.
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        next = DATA;
                        bit_count_next = 1'b0;
                        tick_count_next = 1'b0; // next state로 갈때 tick_count 초기화
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_in[bit_count_reg];  // UART LSB first

                if (tick) begin
                    if (tick_count_reg == 15) begin
                        tick_count_next = 0; // 다음 상태로 가기전에 초기화
                        if (bit_count_reg == 7) begin
                            next = STOP;
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;  // bit count 증가
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

// UART RX
module uart_rx (
    input  logic       clk,
    input  logic       rst,
    input  logic       tick,
    input  logic       rx,
    output logic       rx_done,
    output logic [7:0] rx_data
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    logic [1:0] state, next;
    logic rx_done_reg, rx_done_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [4:0] tick_count_reg, tick_count_next;  // rx tick max count 24.
    logic [7:0] rx_data_reg, rx_data_next;
    // output
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    // state
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            rx_done_reg    <= 0;
            rx_data_reg    <= 1;
            bit_count_reg  <= 0;
            tick_count_reg <= 0;
        end else begin
            state          <= next;
            rx_done_reg    <= rx_done_next;
            rx_data_reg    <= rx_data_next;
            bit_count_reg  <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    // next
    always @(*) begin
        next = state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        rx_done_next = 1'b0;
        rx_data_next = rx_data_reg;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next  = 0;
                rx_done_next    = 1'b0;
                if (rx == 1'b0) begin
                    next = START;
                end
            end
            START: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 7) begin
                        next = DATA;
                        tick_count_next = 0;  // init tick count
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        // read data 
                        rx_data_next[bit_count_reg] = rx;
                        if (bit_count_reg == 7) begin
                            next = STOP;
                            tick_count_next = 0;  // tick count 초기화
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                            tick_count_next = 0;  // tick count 초기화
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 23) begin
                        rx_done_next = 1'b1;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module baud_tick_gen (
    input  logic clk,
    input  logic rst,
    output logic baud_tick
);
    parameter BAUD_RATE = 115200;  //, BAUD_RATE_19200 = 19200, ;
    localparam BAUD_COUNT = 100_000_000 / BAUD_RATE / 16;
    logic [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;
    logic tick_reg, tick_next;
    // output
    assign baud_tick = tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    // next
    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule
