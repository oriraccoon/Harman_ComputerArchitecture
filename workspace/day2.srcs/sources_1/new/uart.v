module uart (
    input  clk,
    input  rst,
    input  rx,
    output tx,
    output reg [7:0] buff_data
);

    wire [7:0] data;
    wire baud_tick;
    wire start_trigger;

    baud_rate U_Baud_tick(
        .clk(clk),
        .rst(rst),
        .baud_clk(baud_tick)
    );

    uart_rx u_rx(
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .rx(rx),
        .rx_busy(rx_busy),
        .start_trigger(start_trigger),
        .rx_data(data)
    );

    uart_tx u_tx(
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_data(buff_data),
        .start_trigger(!rx_busy & start_trigger),
        .tx_busy(tx_busy),
        .tx(tx)
    );

    always @(*) begin
        if(!rx_busy) buff_data = data;
        else buff_data = buff_data;
    end

endmodule

module uart_rx (
    input clk,
    input rst,
    input baud_tick,
    input rx,
    output reg rx_busy,
    output reg start_trigger,
    output reg [7:0] rx_data
);
    
    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state;
    reg [$clog2(24)-1:0] tick_count;
    reg [2:0] bit_count;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            tick_count <= 0;
            rx_busy <= 0;
            bit_count <= 0;
            rx_data <= 0;
            start_trigger <= 0;
        end else begin
            case (state)
                IDLE: begin
                    rx_busy <= 0;
                    rx_data <= 0;
                    tick_count <= 0;
                    if(~rx) begin
                        state <= START;
                        start_trigger <= 1;
                    end
                end
                START: begin
                    rx_busy <= 1;
                    start_trigger <= 0;
                    if(baud_tick) begin
                        if(tick_count == 7) begin
                            state <= DATA;
                            tick_count <= 0;
                            bit_count <= 0;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end
                DATA: begin
                    if(baud_tick) begin
                        if(tick_count == 15) begin
                            tick_count <= 0;
                            rx_data[bit_count] <= rx;
                            if(bit_count == 7) begin
                                state <= STOP;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end
                STOP: begin
                    if(baud_tick) begin
                        if(tick_count == 23) begin
                            rx_busy <= 0;
                            state <= IDLE;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end 
            endcase
        end
    end


endmodule

module uart_tx (
    input clk,
    input rst,
    input baud_tick,
    input [7:0] tx_data,
    input start_trigger,
    output reg tx_busy,
    output reg tx
);
    
    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state;
    reg [3:0] tick_count;
    reg [2:0] bit_count;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            tick_count <= 0;
            tx_busy <= 0;
            tx <= 1;
            bit_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1;
                    tx_busy <= 0;
                    if(start_trigger) begin
                        state <= START;
                        tx_busy <= 1;
                        tx <= 0;
                    end
                end
                START: begin
                    if(baud_tick) begin
                        if(tick_count == 15) begin
                            state <= DATA;
                            tick_count <= 0;
                            bit_count <= 0;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end
                DATA: begin
                    if(baud_tick) begin
                        if(tick_count == 15) begin
                            tick_count <= 0;
                            tx <= tx_data[bit_count];
                            if(bit_count == 7) begin
                                state <= STOP;
                            end else begin
                                bit_count <= bit_count + 1;
                            end
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end
                STOP: begin
                    tx <= 1;
                    if(baud_tick) begin
                        if(tick_count == 15) begin
                            state <= IDLE;
                        end else begin
                            tick_count <= tick_count + 1;
                        end
                    end
                end 
            endcase
        end
    end

endmodule

module baud_rate (
    input clk,
    input rst,
    output reg baud_clk
);

    parameter BAUD = 115200;
    parameter FCOUNT = 100_000_000 / BAUD / 16;
    reg [$clog2(FCOUNT)-1:0] baud_count;

    always @(posedge clk or posedge rst) begin
        if(rst) baud_count <= 0;
        else begin
            if(baud_count == FCOUNT - 1) begin
                baud_clk <= 1;
                baud_count <= 0;
            end else begin
                baud_count <= baud_count + 1;
                baud_clk <= 0;
            end
        end
    end


endmodule