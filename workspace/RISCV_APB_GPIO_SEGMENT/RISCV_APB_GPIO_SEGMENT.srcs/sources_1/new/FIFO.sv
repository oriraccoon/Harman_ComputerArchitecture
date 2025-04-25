`timescale 1ns / 1ps

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
