module uart_fnd(
    input        clk,
    input        rst,
    output [3:0] fndCom,
    output [7:0] fndFont,

    input       rx,
    output      tx
    );

    uart U_uart(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx),
        .rx_done(rx_done),
        .data(data)
    );

    top_counter_up_down U_fnd(
        .clk(clk),
        .rst(rst),
        .read_signal(rx_done),
        .uart_data(data),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );  

endmodule