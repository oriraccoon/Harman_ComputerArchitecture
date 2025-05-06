`timescale 1ns / 1ps

module rgb_led (
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
    output logic        red,
    output logic        green,
    output logic        blue
);
    logic [2:0] rgbCtrlReg;

    APB_rgb u_APB_rgb (
        .PCLK      (PCLK),
        .PRESET    (PRESET),
        .PADDR     (PADDR),
        .PWDATA    (PWDATA),
        .PWRITE    (PWRITE),
        .PENABLE   (PENABLE),
        .PSEL      (PSEL),
        .PRDATA    (PRDATA),
        .PREADY    (PREADY),
        .rgbCtrlReg(rgbCtrlReg)
    );

    rgb_led_ip u_rgb_led_ip (
        .clk     (PCLK),
        .reset   (PRESET),
        .rgb_ctrl(rgbCtrlReg),
        .red     (red),
        .green   (green),
        .blue    (blue)
    );


endmodule

module APB_rgb (
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
    output logic [ 2:0] rgbCtrlReg
);
    logic [31:0] slv_reg0;  //, slv_reg1, slv_reg2, slv_reg3;

    assign rgbCtrlReg = slv_reg0[2:0];

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

module rgb_led_ip (
    input  logic       clk,
    input  logic       reset,
    input  logic [2:0] rgb_ctrl,
    output logic       red,
    output logic       green,
    output logic       blue
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            red   <= 0;
            green <= 0;
            blue  <= 0;
        end else begin
            red   <= rgb_ctrl[2];
            green <= rgb_ctrl[1];
            blue  <= rgb_ctrl[0];
        end
    end
endmodule
