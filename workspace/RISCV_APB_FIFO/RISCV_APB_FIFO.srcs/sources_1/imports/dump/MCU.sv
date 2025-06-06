`timescale 1ns / 1ps

module MCU (
    input  logic       clk,
    input  logic       reset,
    inout  logic [7:0] GPIOB,
    inout  logic [7:0] GPIOC,
    inout  logic [7:0] GPIOD,
    output logic [7:0] fndFont,
    output logic [3:0] fndCom,
    output logic       trig,
    input  logic       echo,
    inout  logic       dht_io,
    output logic [2:0] led,
    output logic buzzer
);
    // global signals
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL_RAM;
    logic        PSEL_TIMER;
    logic        PSEL_GPIOB;
    logic        PSEL_GPIOC;
    logic        PSEL_GPIOD;
    logic        PSEL_FND;
    logic        PSEL_ULTRA;
    logic        PSEL_DHT;
    logic        PSEL_BLINK;
    logic        PSEL_BUZZER;
    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_TIMER;
    logic [31:0] PRDATA_GPIOB;
    logic [31:0] PRDATA_GPIOC;
    logic [31:0] PRDATA_GPIOD;
    logic [31:0] PRDATA_FND;
    logic [31:0] PRDATA_ULTRA;
    logic [31:0] PRDATA_DHT;
    logic [31:0] PRDATA_BLINK;
    logic [31:0] PRDATA_BUZZER;
    logic        PREADY_RAM;
    logic        PREADY_TIMER;
    logic        PREADY_GPIOB;
    logic        PREADY_GPIOC;
    logic        PREADY_GPIOD;
    logic        PREADY_FND;
    logic        PREADY_ULTRA;
    logic        PREADY_DHT;
    logic        PREADY_BLINK;
    logic        PREADY_BUZZER;

    // CPU - APB_Master Signals
    // Internal Interface Signals
    logic        transfer;  // trigger signal
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;  // 1:write, 0:read
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] dataRData;

    // ROM Signals
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;

    assign PCLK = clk;
    assign PRESET = reset;
    assign addr = dataAddr;
    assign wdata = dataWData;
    assign dataRData = rdata;
    assign write = dataWe;

    rom U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    RV32I_Core U_Core (.*);

    APB_Master U_APB_Master (
        .*,
        .PSEL0  (PSEL_RAM),
        .PSEL1  (PSEL_TIMER),
        .PSEL2  (PSEL_GPIOB),
        .PSEL3  (PSEL_GPIOC),
        .PSEL4  (PSEL_GPIOD),
        .PSEL5  (PSEL_FND),
        .PSEL6  (PSEL_ULTRA),
        .PSEL7  (PSEL_DHT),
        .PSEL8  (PSEL_BLINK),
        .PSEL9  (PSEL_BUZZER),
        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_TIMER),
        .PRDATA2(PRDATA_GPIOB),
        .PRDATA3(PRDATA_GPIOC),
        .PRDATA4(PRDATA_GPIOD),
        .PRDATA5(PRDATA_FND),
        .PRDATA6(PRDATA_ULTRA),
        .PRDATA7(PRDATA_DHT),
        .PRDATA8(PRDATA_BLINK),
        .PRDATA9(PRDATA_BUZZER),
        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_TIMER),
        .PREADY2(PREADY_GPIOB),
        .PREADY3(PREADY_GPIOC),
        .PREADY4(PREADY_GPIOD),
        .PREADY5(PREADY_FND),
        .PREADY6(PREADY_ULTRA),
        .PREADY7(PREADY_DHT),
        .PREADY8(PREADY_BLINK),
        .PREADY9(PREADY_BUZZER)
    );

    ram U_RAM (
        .*,
        .PSEL  (PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    Timer_Periph U_Timer (
        .*,
        .PSEL(PSEL_TIMER),
        .PRDATA(PRDATA_TIMER),
        .PREADY(PREADY_TIMER)
    );

    GPIO_Periph U_GPIOB (
        .*,
        .PSEL(PSEL_GPIOB),
        .PRDATA(PRDATA_GPIOB),
        .PREADY(PREADY_GPIOB),
        .inOutPort(GPIOB)
    );

    GPIO_Periph U_GPIOC (
        .*,
        .PSEL(PSEL_GPIOC),
        .PRDATA(PRDATA_GPIOC),
        .PREADY(PREADY_GPIOC),
        .inOutPort(GPIOC)
    );

    GPIO_Periph U_GPIOD (
        .*,
        .PSEL(PSEL_GPIOD),
        .PRDATA(PRDATA_GPIOD),
        .PREADY(PREADY_GPIOD),
        .inOutPort(GPIOD)
    );

    FndController_Periph U_FndController_Periph (
        .*,
        .PSEL  (PSEL_FND),
        .PRDATA(PRDATA_FND),
        .PREADY(PREADY_FND)
    );

    Ultrasonic_Periph U_Ultrasonic_Periph (
        .*,
        .PSEL  (PSEL_ULTRA),
        .PRDATA(PRDATA_ULTRA),
        .PREADY(PREADY_ULTRA),
        .echo(echo),
        .trig(trig)
    );

    Humidity_Periph U_Humidity_Periph (
        .*,
        .PSEL  (PSEL_DHT),
        .PRDATA(PRDATA_DHT),
        .PREADY(PREADY_DHT),
        .dht_io(dht_io)
    );

    blink_Periph U_blink_Periph (
        .*,
        .PSEL  (PSEL_BLINK),
        .PRDATA(PRDATA_BLINK),
        .PREADY(PREADY_BLINK),
        .led(led)
    );

    blink_Periph U_buzzer_Periph (
        .*,
        .PSEL  (PSEL_BUZZER),
        .PRDATA(PRDATA_BUZZER),
        .PREADY(PREADY_BUZZER),
        .led(buzzer)
    );

endmodule


