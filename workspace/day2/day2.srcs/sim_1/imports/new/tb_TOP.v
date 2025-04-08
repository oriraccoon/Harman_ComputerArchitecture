module tb_TOP ();
reg clk, rst, rx;


Top_Uart_Watch DUT(
    .clk(clk),
    .rst(rst),
    // UART_FIFO
    .rx(rx)
    );


    always #1 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        rx = 1;

        #20 
        rst = 0;
        #2
        
        rx = 0; #869; send_bit("r"); rx = 1; #2604;
        #2
        rx = 0; #869; send_bit("c"); rx = 1; #2604;
                #2
        rx = 0; #869; send_bit("m"); rx = 1; #2604;
                #2
        rx = 0; #869; send_bit("m"); rx = 1; #2604;
                #2
        rx = 0; #869; send_bit("m"); rx = 1; #2604;
                #200
        rx = 0; #869; send_bit("t"); rx = 1; #2604;
        #2000000
        rx = 0; #869; send_bit("m"); rx = 1; #2604;
                #2
        rx = 0; #869; send_bit("m"); rx = 1; #2604;
                #2
        rx = 0; #869; send_bit("h"); rx = 1; #2604;
        #10000;
        $finish;
    end

    task send_bit(input [7:0] data);
        integer i;
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #1738;
        end
    endtask


endmodule
