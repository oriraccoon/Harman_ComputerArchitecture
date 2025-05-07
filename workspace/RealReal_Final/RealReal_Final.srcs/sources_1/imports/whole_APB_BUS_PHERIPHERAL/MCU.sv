`timescale 1ns / 1ps

module MCU (
    input  logic       clk,
    input  logic       reset,
    inout  logic [7:0] GPIOA,
    inout  logic [7:0] GPIOB,
    inout  logic [7:0] GPIOC,
    output logic [7:0] fndFont,
    output logic [3:0] fndCom,
    output logic       trig,
    input  logic       echo,
    inout  logic       dht_io,
    output logic [2:0] led,
    output logic buzzer,

    //UART PORT
    output logic       tx,
    input logic        rx,

    //TILT, RGB PORT
    input  logic       tilt_sensor

    // output logic  BUZZER, //BUZZER
    // output logic  PWM //pwm_out
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
    logic        PSEL_GPIOA;
    logic        PSEL_GPIOB;
    logic        PSEL_GPIOC;
    logic        PSEL_FND;
    logic        PSEL_ULTRA;
    logic        PSEL_DHT;
    logic        PSEL_BLINK;
    logic        PSEL_TIMER2;
    logic        PSEL_UART;
    logic        PSEL_BUZZER;
    logic        PSEL_TILT;
    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_TIMER;
    logic [31:0] PRDATA_GPIOA;
    logic [31:0] PRDATA_GPIOB;
    logic [31:0] PRDATA_GPIOC;
    logic [31:0] PRDATA_FND;
    logic [31:0] PRDATA_ULTRA;
    logic [31:0] PRDATA_DHT;
    logic [31:0] PRDATA_BLINK;
    logic [31:0] PRDATA_TIMER2;
    logic [31:0] PRDATA_UART;
    logic [31:0] PRDATA_BUZZER;
    logic [31:0] PRDATA_TILT;
    logic        PREADY_RAM;
    logic        PREADY_TIMER;
    logic        PREADY_GPIOA;
    logic        PREADY_GPIOB;
    logic        PREADY_GPIOC;
    logic        PREADY_FND;
    logic        PREADY_ULTRA;
    logic        PREADY_DHT;
    logic        PREADY_BLINK;
    logic        PREADY_TIMER2;
    logic        PREADY_UART;
    logic        PREADY_BUZZER;
    logic        PREADY_TILT;

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
        .PSEL2  (PSEL_GPIOA),
        .PSEL3  (PSEL_GPIOB),
        .PSEL4  (PSEL_GPIOC),
        .PSEL5  (PSEL_FND),
        .PSEL6  (PSEL_ULTRA),
        .PSEL7  (PSEL_DHT),
        .PSEL8  (PSEL_BLINK),
        .PSEL9  (PSEL_TIMER2),
        .PSEL10  (PSEL_UART),
        .PSEL11  (PSEL_TILT),
        .PSEL12  (),
        .PSEL13  (PSEL_BUZZER),
        .PRDATA0(PRDATA_RAM),
        .PRDATA1(PRDATA_TIMER),
        .PRDATA2(PRDATA_GPIOA),
        .PRDATA3(PRDATA_GPIOB),
        .PRDATA4(PRDATA_GPIOC),
        .PRDATA5(PRDATA_FND),
        .PRDATA6(PRDATA_ULTRA),
        .PRDATA7(PRDATA_DHT),
        .PRDATA8(PRDATA_BLINK),
        .PRDATA9(PRDATA_TIMER2),
        .PRDATA10(PRDATA_UART),
        .PRDATA11(PRDATA_TILT),
        .PRDATA12(),
        .PRDATA13(PRDATA_BUZZER),
        .PREADY0(PREADY_RAM),
        .PREADY1(PREADY_TIMER),
        .PREADY2(PREADY_GPIOA),
        .PREADY3(PREADY_GPIOB),
        .PREADY4(PREADY_GPIOC),
        .PREADY5(PREADY_FND),
        .PREADY6(PREADY_ULTRA),
        .PREADY7(PREADY_DHT),
        .PREADY8(PREADY_BLINK),
        .PREADY9(PREADY_TIMER2),
        .PREADY10(PREADY_UART),
        .PREADY11(PREADY_TILT),
        .PREADY12(),
        .PREADY13(PREADY_BUZZER)
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

    GPIO_Periph U_GPIOA (
        .*,
        .PSEL(PSEL_GPIOA),
        .PRDATA(PRDATA_GPIOA),
        .PREADY(PREADY_GPIOA),
        .inOutPort(GPIOA)
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

    Timer_Periph U_Timer2 (
        .*,
        .PSEL(PSEL_TIMER2),
        .PRDATA(PRDATA_TIMER2),
        .PREADY(PREADY_TIMER2)
    );

    UART_Periph U_UART_Periph(
        .*,
        .PSEL(PSEL_UART),
        .PRDATA(PRDATA_UART),
        .PREADY(PREADY_UART)
);
    tilt U_Tilt (
        .*,
        .PSEL  (PSEL_TILT),
        .PRDATA(PRDATA_TILT),
        .PREADY(PREADY_TILT),
        .tilt_sensor(tilt_sensor)
    );


endmodule


