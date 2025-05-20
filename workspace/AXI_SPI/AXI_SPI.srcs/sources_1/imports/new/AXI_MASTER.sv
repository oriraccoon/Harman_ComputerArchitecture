`timescale 1ns / 1ps

module AXI4_Lite_MASTER (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // WRITE Transaction. AW Channel
    output logic [ 3:0] AWADDR,
    output logic        AWVALID,
    input  logic        AWREADY,
    // WRITE Transaction. W Channel
    output logic [31:0] WDATA,
    output logic        WVALID,
    input  logic        WREADY,
    // WRITE Transaction. B Channel
    input  logic [ 1:0] BRESPONSE,
    input  logic        BVALID,
    output logic        BREADY,
    // READ Transaction. AR Channel
    output logic [ 3:0] ARADDR,
    output logic        ARVALID,
    input  logic        ARREADY,
    // READ Transaction. R Channel
    input  logic [31:0] RDATA,
    input  logic        RVALID,
    output logic        RREADY,

    // internal signals
    input  logic        transfer,
    output logic        ready,
    input  logic [ 3:0] addr,
    input  logic [31:0] wdata,
    input  logic        write,
    output logic [31:0] rdata
);



    // WRITE Transaction, AW Channel transfer
    typedef enum {
        AW_IDLE_S,
        AW_VALID_S
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state <= AW_IDLE_S;
        end else begin
            aw_state <= aw_state_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state;
        AWVALID       = 1'b0;
        AWADDR        = addr;
        case (aw_state)
            AW_IDLE_S: begin
                AWVALID = 1'b0;
                if (transfer && write) begin
                    aw_state_next = AW_VALID_S;
                end
            end
            AW_VALID_S: begin
                AWVALID = 1'b1;
                if (AWREADY) begin
                    aw_state_next = AW_IDLE_S;
                end
            end
        endcase
    end



    // WRITE Transaction, W Channel transfer
    typedef enum {
        W_IDLE_S,
        W_VALID_S
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE_S;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WVALID       = 1'b0;
        WDATA        = wdata;
        case (aw_state)
            W_IDLE_S: begin
                WVALID = 1'b0;
                if (transfer && write) begin
                    w_state_next = W_VALID_S;
                end
            end
            W_VALID_S: begin
                WVALID = 1'b1;
                if (WREADY) begin
                    w_state_next = W_IDLE_S;
                end
            end
        endcase
    end



    // WRITE Transaction, B Channel transfer
    typedef enum {
        B_IDLE_S,
        B_READY_S
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE_S;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        BREADY       = 1'b0;
        ready        = 1'b0;
        case (b_state)
            B_IDLE_S: begin
                BREADY = 1'b0;
                ready  = 1'b0;
                if (WVALID) begin
                    b_state_next = B_READY_S;
                end
            end
            B_READY_S: begin
                BREADY = 1'b1;
                if (BVALID) begin
                    ready        = 1'b1;
                    b_state_next = B_IDLE_S;
                end
            end
        endcase
    end




    // READ Transaction, AR Channel transfer
    typedef enum {
        AR_IDLE_S,
        AR_VALID_S
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state <= AR_IDLE_S;
        end else begin
            ar_state <= ar_state_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ARVALID       = 1'b0;
        ARADDR        = addr;
        case (ar_state)
            AR_IDLE_S: begin
                ARVALID = 1'b0;
                if (transfer && !write) begin
                    ar_state_next = AR_VALID_S;
                end
            end
            AR_VALID_S: begin
                ARVALID = 1'b1;
                if (ARREADY) begin
                    ar_state_next = AR_IDLE_S;
                end
            end
        endcase
    end



    // READ Transaction, R Channel transfer
    typedef enum {
        R_IDLE_S,
        R_VALID_S
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE_S;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RREADY       = 1'b0;
        rdata        = RDATA;
        case (ar_state)
            R_IDLE_S: begin
                RREADY = 1'b0;
                if (transfer && !write) begin
                    r_state_next = R_VALID_S;
                end
            end
            R_VALID_S: begin
                RREADY = 1'b1;
                if (RVALID) begin
                    r_state_next = R_IDLE_S;
                end
            end
        endcase
    end


endmodule
