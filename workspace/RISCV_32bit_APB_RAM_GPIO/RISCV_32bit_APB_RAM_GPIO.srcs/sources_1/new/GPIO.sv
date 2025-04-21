module GPIO (
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL_GPO,
    output logic [31:0] PRDATA_GPO,
    output logic        PREADY_GPO,
    input  logic        PSEL_GPI,
    output logic [31:0] PRDATA_GPI,
    output logic        PREADY_GPI,
    // export signals
    inout  logic [ 7:0] inoutPort
);

    logic [7:0] inPort;
    logic [7:0] outPort;

    assign inoutPort = PWRITE ? outPort : 8'bz;
    assign inPort = inoutPort;

    GPO_Periph U_GPO (
        .*,
        .PSEL(PSEL_GPO),
        .PRDATA(PRDATA_GPO),
        .PREADY(PREADY_GPO),
        .outPort(inoutPort)
    );

    GPI_Periph U_GPI (
        .*,
        .PSEL(PSEL_GPI),
        .PRDATA(PRDATA_GPI),
        .PREADY(PREADY_GPI),
        .inPort(inoutPort)
    );

endmodule


module GPO_Periph (
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
    // export signals
    output logic [ 7:0] outPort
);

    logic [7:0] moder;
    logic [7:0] odr;

    GPO U_GPO_IP (.*);

    APB_Slave_Intf_GPO U_APB_Slave_Intf_GPO (.*);

endmodule

module APB_Slave_Intf_GPO (
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
    output logic [ 7:0] moder,
    output logic [ 7:0] odr
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2, slv_reg3;

    assign {moder, odr} = {slv_reg0[7:0], slv_reg1[7:0]};

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

module GPO (
    input  logic [7:0] moder,
    input  logic [7:0] odr,
    output logic [7:0] outPort
);

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            assign outPort[i] = moder[i] ? odr[i] : 1'bz;
        end
    endgenerate


endmodule

module GPI_Periph (
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
    // export signals
    input  logic [ 7:0] inPort
);

    logic [7:0] moder;
    logic [7:0] idr;

    GPI U_GPI_IP (.*);

    APB_Slave_Intf_GPI U_APB_Slave_Intf_GPI (.*);

endmodule

module APB_Slave_Intf_GPI (
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
    input  logic [ 7:0] idr,
    output logic [ 7:0] moder
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2, slv_reg3;

    assign {moder, slv_reg1[7:0]} = {slv_reg0[7:0], idr};

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

module GPI (
    input  logic [7:0] moder,
    input  logic [7:0] inPort,
    output logic [7:0] idr
);

    generate
        for (genvar i = 0; i < 8; i = i + 1) begin
            assign idr[i] = ~moder[i] ? inPort[i] : 1'bz;
        end
    endgenerate


endmodule
