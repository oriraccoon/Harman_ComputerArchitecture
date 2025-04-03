module uart_fnd(
    input        clk,
    input        rst,
    output [3:0] fndCom,
    output [7:0] fndFont,

    input       rx,
    output      tx
    );

    wire rx_done;
    wire [7:0] rx_data, tx_data;

    uart U_uart(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx_data(tx_data),
        .tx(tx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

    top_counter_up_down U_fnd(
        .clk(clk),
        .rst(rst),
        .read_signal(rx_done),
        .uart_data(rx_data),
        .fndCom(fndCom),
        .fndFont(fndFont),
        .o_data(tx_data)
    );  

endmodule