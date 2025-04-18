module APB_Master (
    // global signal
    input  logic        PCLK,
    input  logic        PRST,
    // APB Interface Signals
    output logic [31:0] PADDR,
    output logic        PENABLE,
    output logic        PWRITE,
    output logic [31:0] PWDATA,
    output logic        PSEL0,
    output logic        PSEL1,
    output logic        PSEL2,
    output logic        PSEL3,
    input  logic [31:0] PRDATA0,
    input  logic [31:0] PRDATA1,
    input  logic [31:0] PRDATA2,
    input  logic [31:0] PRDATA3,
    input  logic        PREADY0,
    input  logic        PREADY1,
    input  logic        PREADY2,
    input  logic        PREADY3,
    // Internal Interface Signals
    input  logic        transfer,  // trigger signal
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        we,        // 1:write, 0:read
    output logic [31:0] rdata,
    output logic        ready
);

    typedef enum bit [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e state, state_next;

    logic [31:0] temp_addr_reg, temp_addr_next;
    logic [31:0] temp_wdata_reg, temp_wdata_next;
    logic temp_we_reg, temp_we_next;
    logic       decoer_en;
    logic [3:0] pselx;

    assign {PSEL0, PSEL1, PSEL2, PSEL3} = pselx;

    APB_Decoder U_APB_Decoder (
        .en (decoer_en),
        .sel(temp_addr_reg),
        .y  (pselx)
    );

    APB_Mux U_APB_Mux (
        .sel(),
        .d0(),
        .d1(),
        .d2(),
        .d3(),
        .r0(),
        .r1(),
        .r2(),
        .r3(),
        .rdata(),
        .ready()
    );


    always_ff @(posedge PCLK or posedge PRST) begin
        if (PRST) begin
            state <= IDLE;
            temp_addr_reg <= 0;
            temp_wdata_reg <= 0;
            temp_we_reg <= 0;
        end else begin
            state          <= state_next;
            temp_addr_reg  <= temp_addr_next;
            temp_wdata_reg <= temp_wdata_next;
            temp_we_reg    <= temp_we_next;
        end
    end

    always_comb begin
        state_next      = state;
        temp_addr_next  = temp_addr_reg;
        temp_wdata_next = temp_wdata_reg;
        temp_we_next    = temp_we_reg;
        decoer_en       = 1'b0;
        PENABLE         = 1'b0;
        case (state)
            IDLE: begin
                decoer_en = 1'b0;
                if (transfer) begin
                    state_next      = SETUP;
                    temp_addr_next  = addr;  // latching
                    temp_wdata_next = wdata;
                    temp_we_next    = we;
                end
            end
            SETUP: begin
                decoer_en = 1'b1;
                PADDR = temp_addr_reg;
                PENABLE = 1'b0;
                if (temp_we_reg) begin
                    PWRITE = 1'b1;
                    PWDATA = temp_wdata_reg;
                end else begin
                    PWRITE = 1'b0;
                end
                state_next = ACCESS;
            end
            ACCESS: begin
                PADDR = temp_addr_reg;
                decoer_en = 1;
                PENABLE = 1;
                if (temp_we_reg) begin
                    PWRITE = 1'b1;
                    PWDATA = temp_wdata_reg;
                end else begin
                    PWRITE = 1'b0;
                end

                if (PREADY1 & ~transfer) begin
                    state_next = IDLE;
                    rdata = PRDATA1;
                end else if (PREADY1 & transfer) begin
                    state_next = SETUP;
                    rdata = PRDATA1;
                end
            end
        endcase
    end

endmodule

module APB_Master_Intf ();

endmodule

module APB_Decoder (
    input  logic        en,
    input  logic [31:0] sel,
    output logic [ 3:0] y
);

    always_comb begin
        y = 4'b0;
        if (en) begin
            case (sel)
                32'h1000_0xxx: y = 4'b0001;
                32'h1000_1xxx: y = 4'b0010;
                32'h1000_2xxx: y = 4'b0100;
                32'h1000_3xxx: y = 4'b1000;
            endcase
        end
    end

endmodule

module APB_Mux (
    input  logic [31:0] sel,
    input  logic [31:0] d0,
    input  logic [31:0] d1,
    input  logic [31:0] d2,
    input  logic [31:0] d3,
    input  logic        r0,
    input  logic        r1,
    input  logic        r2,
    input  logic        r3,
    output logic [31:0] rdata,
    output logic        ready
);

    always_comb begin
        rdata = 32'bx;
        case (sel)
            32'h1000_0xxx: rdata = d0;
            32'h1000_1xxx: rdata = d1;
            32'h1000_2xxx: rdata = d2;
            32'h1000_3xxx: rdata = d3;
        endcase
    end
    always_comb begin
        ready = 1'bx;
        case (sel)
            32'h1000_0xxx: ready = r0;
            32'h1000_1xxx: ready = r1;
            32'h1000_2xxx: ready = r2;
            32'h1000_3xxx: ready = r3;
        endcase
    end

endmodule
