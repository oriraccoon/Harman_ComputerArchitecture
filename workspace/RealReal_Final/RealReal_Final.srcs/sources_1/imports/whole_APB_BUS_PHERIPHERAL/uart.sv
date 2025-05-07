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
    output logic        tx,
    input logic         rx
);

    logic full, empty;
    logic [7:0] fwd;
    //logic [7:0] frd;
    logic [1:0] fsr;
    logic wr_en;
    logic rd_en;
    logic [7:0] data;

    logic tx_done;

    logic edge_wr, edge_wr_d;
    logic edge_rd, edge_rd_d;


    assign edge_wr = PSEL & PWRITE & PENABLE & PREADY;
    assign edge_rd = (!empty) & tx_done;

    always_ff @( posedge PCLK, posedge PRESET ) begin
        if (PRESET) begin
            edge_rd_d <= 0;
            edge_wr_d <= 0;
        end
        else begin
            edge_wr_d <= edge_wr;
            edge_rd_d <= edge_rd;
        end
    end

    assign wr_en = edge_wr & ~edge_wr_d;
    assign rd_en = edge_rd & ~edge_rd_d;
    assign fsr[0] = empty;
    assign fsr[1] = full;

    APB_SlaveIntf_FIFO U_APB_IntfO_FIFO (.*);

    FIFO U_FIFO (
        .clk  (PCLK),
        .reset(PRESET),
        // write side
        .wdata(fwd),
        .wr_en(wr_en),
        .full (full),
        // read side
        .rdata(data),
        .rd_en(rd_en),
        .empty(empty)
    );

    uart u_uart(
        .clk(PCLK),
        .reset(PRESET),
        .data(data),
        .rx(rx),
        .w_start(tx_done & !empty),
        .tx(tx),
        .tx_done(tx_done)
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
    input logic [1:0] fsr,
    output logic [7:0] fwd
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;//, slv_reg3;

    //assign fsr = slv_reg0[1:0];
    assign fwd = slv_reg1[7:0];
    //assign frd = slv_reg2[7:0];
    /*always_comb begin 
        slv_reg0[1:0] = fsr;
        slv_reg2[7:0] = frd;
    end*/

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            PREADY <= 0;
            PRDATA <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            slv_reg0[1:0] <= fsr;
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        // 2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        // 2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    //slv_reg2[7:0] <= frd; 
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        //2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
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
            empty  <= 1'b1;
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

module uart(
    input logic clk,
    input logic reset,
    input logic rx,
    input logic [7:0] data,
    input logic w_start,
    output logic tx,
    output logic tx_done
);

    logic  w_tick;
    logic  [7:0] rx_data;
    logic  rx_done;

    uart_rx u_rx(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tick(w_tick),
        .data(),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    tick_gen u_tick_gen(
        .clk(clk),
        .reset(reset),
        .tick(w_tick)
    );
    
    uart_tx u_tx(
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .start(w_start),
        .tx_data(data),
        .tx(tx),
        .tx_done(tx_done),
        .tx_busy()
    );

    
endmodule


module uart_rx (
    input clk,
    input reset,
    input rx,
    input tick,
    output [7:0] data,
    output [7:0] rx_data,
    output rx_done
);
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [2:0] state, next;

    reg [7:0] rdata, ndata;
    reg [3:0] icnt, inext;
    
    reg [15:0] tick_cnt, tick_next;

    assign data = (state == IDLE) ? rdata : 0;
    assign rx_done = (state == IDLE);
    assign rx_data = rdata;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            tick_cnt <= 0;
            icnt <= 0;
            rdata <= 0;
        end
        else begin
            state <= next;
            rdata <= ndata;
            tick_cnt <= tick_next;
            icnt <= inext;
        end
    end
    
    always @(*) begin
        next = state;
        tick_next = tick_cnt;
        ndata = rdata;
        inext = icnt;
        case (state)
            IDLE: begin
                if (!rx) begin
                    next = START;
                end 
            end 
            START: begin
                if (tick) begin
                    if (tick_cnt == 15) begin
                        next = DATA;
                        tick_next = 0; 
                    end 
                    else begin
                        tick_next = tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (tick) begin
                    if (tick_cnt == 15) begin
                        ndata[icnt] = rx;
                        tick_next = 0;
                        if (icnt == 7) begin
                            inext = 0;
                            next = STOP;
                        end
                        else begin
                            inext = icnt + 1;
                        end
                    end
                        
                    else begin
                        tick_next = tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (tick) begin
                    if (tick_cnt == 23) begin
                        tick_next = 0;
                        inext = 0;
                        next = IDLE;
                    end
                    else begin
                        tick_next = tick_cnt + 1;
                    end
                end
            end
        endcase
    end
endmodule

module tick_gen (
    input clk,
    input reset,
    output tick
);

    localparam CNT = (100_000_000)/(9600*16);

    reg r_tick;
    assign tick = r_tick;

    reg [$clog2(CNT)-1:0] cnt;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            cnt <= 0;
            r_tick <= 0;
        end
        else begin
            if (cnt == CNT-1) begin
                cnt <= 0;
                r_tick <= 1;
            end
            else begin
                r_tick <= 0;
                cnt <= cnt + 1;
            end
        end
    end
endmodule

module uart_tx (
      input clk,
      input reset,
      input tick,
      input start,
      input [7:0] tx_data,
      output tx,
      output tx_done,
      output tx_busy
      );

    typedef enum logic [1:0] { IDLE = 0, START = 1, DATA = 2, STOP = 3 } state_e;
    state_e state, next;
    
    assign tx_done = (state == IDLE);
    assign tx_busy = (state != IDLE);
    
    logic [7:0] temp_reg, temp_next;
    logic [3:0] rcnt, ncnt;
    logic [2:0] icntr, icntn;
    logic r_tx, n_tx;
    assign tx = r_tx;
    
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            rcnt  <= 0;
            icntr <= 0;
            r_tx  <= 1;
            temp_reg <= 0;
        end
        else begin
            state <= next;
            rcnt  <= ncnt;
            icntr <= icntn;
            r_tx  <= n_tx;
            temp_reg <= temp_next;
        end
    end
    
    always @(*) begin
        next  = state;
        ncnt  = rcnt;
        icntn = icntr;
        n_tx  = r_tx;
        temp_next = temp_reg;
        case (state)
            IDLE: begin
                n_tx = 1;
                if (start) begin
                    next = START;
                    temp_next = tx_data;
                end
            end
            START: begin
                n_tx = 0;
                if (tick) begin
                    if (rcnt == 15) begin
                        next = DATA;
                        ncnt = 0;
                    end
                    else begin
                        ncnt = rcnt + 1;
                    end
                end
            end
            DATA: begin
                n_tx = temp_next[icntr];
                if (tick) begin
                    if (rcnt == 15) begin
                        ncnt = 0;
                        if (icntr == 7) begin
                            next  = STOP;
                            icntn = 0;
                        end
                        else begin
                            icntn = icntr + 1;
                        end
                    end
                    else begin
                        ncnt = rcnt + 1;
                    end
                end
            end
            STOP: begin
                n_tx = 1;
                if (tick) begin
                    if (rcnt == 15) begin
                        next = IDLE;
                        ncnt = 0;
                    end
                    else begin
                        ncnt = rcnt + 1;
                    end
                end
            end
        endcase
    end
endmodule
