module blink_led (
    input logic clk,
    input logic reset,
    input logic [7:0] duty_rate,
    output logic led
);

    parameter SYS_CLK = 100_000_000;
    parameter BASE_CLK = 1000;
    parameter ON_TIME = 200;
    logic [$clog2(2550)-1:0] DUTY = duty_rate * 10;
    logic c_clk;

    clock_divider #(
        .FCOUNT(SYS_CLK / BASE_CLK)
    ) U_divider (
        .clk  (clk),
        .rst  (reset),
        .o_clk(c_clk)
    );

    typedef enum logic [1:0] {
        STATE_ON,
        STATE_OFF
    } state_t;

    state_t state;
    logic [15:0] counter;

    always_ff @(posedge c_clk or posedge reset) begin
        if (reset) begin
            state <= STATE_ON;
            counter <= 0;
            led <= 1;
        end
        else begin
            case (state)
                STATE_ON: begin
                    if (counter >= ON_TIME) begin
                        counter <= 0;
                        if (DUTY <= 30) begin
                            state <= STATE_ON;
                            led <= 1;
                        end
                        else begin
                            state <= STATE_OFF;
                            led <= 0;
                        end
                    end
                    else begin
                        counter <= counter + 1;
                        led <= 1;
                    end
                end

                STATE_OFF: begin
                    if (counter >= DUTY) begin
                        counter <= 0;
                        state <= STATE_ON;
                        led <= 1;
                    end
                    else begin
                        counter <= counter + 1;
                        led <= 0;
                    end
                end

                default: begin
                    state <= STATE_ON;
                    counter <= 0;
                    led <= 1;
                end
            endcase
        end
    end

endmodule
