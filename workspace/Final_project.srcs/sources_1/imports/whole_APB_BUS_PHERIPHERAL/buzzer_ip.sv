`timescale 1ns / 1ps
module Buzzer_Periph (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        buzzer_out, 
    output logic        pwm_out      
);

    logic [31:0] en_reg;     // EN 레지스터 
    logic [31:0] duty_reg;   // DUTY 레지스터
    logic [31:0] period_reg; // PERIOD 레지스터
    
 
    assign buzzer_out = (en_reg[0]) ? pwm_out : 1'b0;
    

    APB_SlaveIntf_Buzzer U_APB_Intf (
        .*
    );
    

    PWM_Generator U_PWM (
        .*, 
        .duty(duty_reg), 
        .period(period_reg), 
        .pwm_out(pwm_out)
    );
endmodule


// APB 슬레이브 인터페이스 
module APB_SlaveIntf_Buzzer (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [3:0]  PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic [31:0] en_reg,
    output logic [31:0] duty_reg,
    output logic [31:0] period_reg
);



    logic [31:0] slv_reg0;  // EN
    logic [31:0] slv_reg1;  // DUTY
    logic [31:0] slv_reg2;  // PERIOD

    // 레지스터 할당
    assign en_reg     = slv_reg0;
    assign duty_reg   = slv_reg1;
    assign period_reg = slv_reg2;
    
    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;        // EN = 0 (OFF)
            slv_reg1 <= 500;      // DUTY = 500 (50% duty cycle default)
            slv_reg2 <= 1000;     // PERIOD = 1000 (default period)
            PREADY   <= 0;
            PRDATA   <= 0;
        end else begin
            PREADY <= 1'b0;
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])  
                        2'd0: slv_reg0 <= PWDATA;  
                        2'd1: slv_reg1 <= PWDATA;  
                        2'd2: slv_reg2 <= PWDATA;  
                    endcase
                end else begin
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;  // EN
                        2'd1: PRDATA <= slv_reg1;  // DUTY
                        2'd2: PRDATA <= slv_reg2;  // PERIOD
                        default: PRDATA <= 0;
                    endcase
                end
                end else begin
                    PREADY <= 1'b0;
                end
            end
        end
endmodule

// PWM Generator
module PWM_Generator (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] duty,
    input  logic [31:0] period,
    output logic        pwm_out
);

    logic [31:0] cnt;
    logic [31:0] clk_div;  // 클럭 분주기
    logic        clk_en;
    logic [31:0] safe_duty;
    
    assign safe_duty = (duty > period) ? period : duty;
    
    // 클럭 분주기 설정
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div <= 0;
            clk_en <= 0;
        end else begin
            if (clk_div >= 32'd50000) begin  // 100MHz / 50000 = 2kHz
                clk_div <= 0;
                clk_en <= 1;
            end else begin
                clk_div <= clk_div + 1;
                clk_en <= 0;
            end
        end
    end
    
    // PWM 카운터
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            pwm_out <= 0;
        end else if (clk_en) begin
            if (cnt >= period || period == 0)
                cnt <= 0;
            else
                cnt <= cnt + 1;
                
            pwm_out <= (cnt < safe_duty && period > 0);
        end
    end
endmodule
