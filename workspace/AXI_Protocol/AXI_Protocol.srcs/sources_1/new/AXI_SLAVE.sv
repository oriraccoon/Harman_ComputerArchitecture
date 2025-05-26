`timescale 1ns / 1ps

module AXI4_Lite_SLAVE (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // WRITE Transaction. AW Channel
    input  logic [ 3:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // WRITE Transaction. W Channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // WRITE Transaction. B Channel
    output logic [ 1:0] BRESPONSE,
    output logic        BVALID,
    input  logic        BREADY,
    // READ Transaction. AR Channel
    input  logic [ 3:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // READ Transaction. R Channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY
);

    logic [31:0] slv_reg0_reg, slv_reg0_next;
    logic [31:0] slv_reg1_reg, slv_reg1_next;
    logic [31:0] slv_reg2_reg, slv_reg2_next;
    logic [31:0] slv_reg3_reg, slv_reg3_next;

    logic [31:0] RDATA_next;

    logic [3:0] aw_addr_reg, aw_addr_next;

    // WRITE Transaction, AW Channel transfer
    typedef enum {
        AW_IDLE_S,
        AW_READY_S
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state    <= AW_IDLE_S;
            aw_addr_reg <= 0;
        end else begin
            aw_state    <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state;
        AWREADY       = 1'b0;
        aw_addr_next  = aw_addr_reg;
        case (aw_state)
            AW_IDLE_S: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next = AW_READY_S;
                    aw_addr_next  = AWADDR;
                end
            end
            AW_READY_S: begin
                AWREADY = 1'b1;
                if (AWVALID && AWREADY) begin
                    aw_state_next = AW_IDLE_S;
                end
            end
        endcase
    end

    // WRITE Transaction, W Channel transfer
    typedef enum {
        W_IDLE_S,
        W_READY_S
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE_S;
            slv_reg0_reg <= 32'bx;
            slv_reg1_reg <= 32'bx;
            slv_reg2_reg <= 32'bx;
            slv_reg3_reg <= 32'bx;
        end else begin
            w_state <= w_state_next;
            slv_reg0_reg <= slv_reg0_next;
            slv_reg1_reg <= slv_reg1_next;
            slv_reg2_reg <= slv_reg2_next;
            slv_reg3_reg <= slv_reg3_next;
        end
    end

    always_comb begin
        w_state_next  = w_state;
        WREADY        = 1'b0;
        slv_reg0_next = slv_reg0_reg;
        slv_reg1_next = slv_reg1_reg;
        slv_reg2_next = slv_reg2_reg;
        slv_reg3_next = slv_reg3_reg;
        case (w_state)
            W_IDLE_S: begin
                WREADY = 1'b0;
                if (WVALID) begin
                    w_state_next = W_READY_S;
                end
            end
            W_READY_S: begin
                WREADY = 1'b1;
                if (WVALID) begin
                    w_state_next = W_IDLE_S;
                    case (aw_addr_reg[3:2])
                        2'd0: slv_reg0_next = WDATA;
                        2'd1: slv_reg1_next = WDATA;
                        2'd2: slv_reg2_next = WDATA;
                        2'd3: slv_reg3_next = WDATA;
                    endcase
                end
            end
        endcase
    end

    // WRITE Transaction, B Channel transfer
    typedef enum {
        B_IDLE_S,
        B_VALID_S
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
        BVALID       = 1'b0;
        BRESPONSE    = 2'b00;
        case (b_state)
            B_IDLE_S: begin
                BVALID = 1'b0;
                if (WVALID && WREADY) begin
                    b_state_next = B_VALID_S;
                end
            end
            B_VALID_S: begin
                BRESPONSE = 2'b00;  // OK
                BVALID    = 1'b1;
                if (BREADY) begin
                    b_state_next = B_IDLE_S;
                end
            end
        endcase
    end



    logic [3:0] ar_addr_reg, ar_addr_next;

    // READ Transaction, AR Channel transfer
    typedef enum {
        AR_IDLE_S,
        AR_READY_S
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state    <= AR_IDLE_S;
            ar_addr_reg <= 0;
        end else begin
            ar_state    <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ARREADY       = 1'b0;
        ar_addr_next  = ar_addr_reg;
        case (ar_state)
            AR_IDLE_S: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY_S;
                    ar_addr_next  = ARADDR;
                end
            end
            AR_READY_S: begin
                ARREADY = 1'b1;
                if (ARVALID) begin
                    ar_state_next = AR_IDLE_S;
                end
            end
        endcase
    end

    // READ Transaction, R Channel transfer
    typedef enum {
        R_IDLE_S,
        R_READY_S
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state   <= R_IDLE_S;
            RDATA     <= 32'bx;
        end else begin
            r_state   <= r_state_next;
            RDATA <= RDATA_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RVALID       = 1'b0;
        RDATA_next   = RDATA;
        case (r_state)
            R_IDLE_S: begin
                RVALID = 1'b0;
                if (RREADY) begin
                    r_state_next = R_READY_S;
                end
            end
            R_READY_S: begin
                RVALID = 1'b1;
                if (RREADY) begin
                    r_state_next = R_IDLE_S;
                    case (ar_addr_reg[3:2])
                        2'd0: RDATA_next = slv_reg0_reg;
                        2'd1: RDATA_next = slv_reg1_reg;
                        2'd2: RDATA_next = slv_reg2_reg;
                        2'd3: RDATA_next = slv_reg3_reg;
                    endcase   
                end
            end
        endcase
    end

endmodule
