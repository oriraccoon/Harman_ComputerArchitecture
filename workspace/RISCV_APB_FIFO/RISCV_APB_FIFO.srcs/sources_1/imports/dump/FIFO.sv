`timescale 1ns / 1ps

module FIFO_Periph (
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
    // inport signals
);

    logic full;
    logic empty;
    logic [7:0] fwdr;
    logic [7:0] frdr;
    logic [1:0] en;

    APB_SlaveIntf_FIFO U_APB_IntfO_FIFO (.*);
    FIFO U_FIFO (
        .clk  (PCLK),
        .reset(PRESET),
        // write side
        .wdata(fwdr),
        .wr_en(en[1]),
        .full (full),
        // read side
        .rdata(frdr),
        .rd_en(en[0]),
        .empty(empty)
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
    input  logic        full,
    input  logic        empty,
    output logic [ 1:0] en,
    output logic [ 7:0] fwdr,
    input  logic [ 7:0] frdr
);

    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_next0, slv_next1, slv_next2;  //, slv_reg3;
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

    always_ff @( posedge PCLK or posedge PRESET ) begin
        if (PRESET) begin
            state <= IDLE;
            // slv_reg0 <= 0;
            slv_reg1 <= 0;
            // slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end
        else begin
            state <= next;
            // slv_next0 <= 0;
            slv_next1 <= 0;
            // slv_next2 <= 0;
            // slv_next3 <= 0;
            if(PSEL && PENABLE) PREADY <= 1'b1;
            else PREADY <= 1'b0;
        end
    end

    always_comb begin
        case (state)
            IDLE: begin
                if(PSEL && PENABLE) begin
                    if (~full && PWRITE) begin
                        next = WRITE;
                    end
                    else if(~empty && ~PWRITE) begin
                        next = READ;
                    end
                end
            end
            READ: next = IDLE;
            WRITE: next = IDLE;
        endcase
    end

    always_comb begin
        case (state)
            READ: begin
                wr_en = 1'b1;
                case (PADDR[3:2])
                    // 2'd0: slv_reg0 <= PWDATA;
                    2'd1: slv_next1 = PWDATA;
                    // 2'd2: slv_reg2 <= PWDATA;
                    // 2'd3: slv_reg3 <= PWDATA;
                endcase
            end
            WRITE: begin
                rd_en = 1'b1;
                PRDATA <= 32'bx;
                case (PADDR[3:2])
                    2'd0: PRDATA = slv_reg0;
                    2'd1: PRDATA = slv_reg1;
                    2'd2: PRDATA = slv_reg2;
                    // 2'd3: PRDATA <= slv_reg3;
                endcase
            end
            default: begin
                wr_en = 1'b0;
                rd_en = 1'b0;
                PRDATA = 32'bx;
            end
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

    logic [31:0] mem[0:2**2-1];

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
