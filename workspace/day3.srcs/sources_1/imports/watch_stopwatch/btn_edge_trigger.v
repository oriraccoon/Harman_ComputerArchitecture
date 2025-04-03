// debounce
module btn_edge_trigger #(
    parameter SET_HZ = 100_000
)(
                        input clk,
                        input rst,
                        input i_btn,
                        output o_btn
);

    wire o_clk, Edge_trigger;
    wire edge_detect;
    reg [7:0] q_reg;
    wire [7:0] q_next;
    

Hz_changer #(.FCOUNT(SET_HZ)) khc(
    .clk(clk),
    .rst(rst),
    .o_clk(o_clk)
);

Shift_Register_8 sr(
    .clk(o_clk),
    .rst(rst),
    .i_btn(i_btn),
    .q_reg(q_reg),
    .q_next(q_next)
);

AND_Gate_8input ag(
    .q_reg(q_reg),
    .Edge_trigger(Edge_trigger)
);

Edge_detecter ed(
    .clk(clk),
    .rst(rst),
    .Edge_trigger(Edge_trigger),
    .edge_detect(edge_detect)
);

    always @(posedge o_clk, posedge rst) begin
        if(rst) q_reg <= 0;
        else q_reg <= q_next;
    end

    assign o_btn = Edge_trigger & ~edge_detect;

endmodule


// 1. clock 100MHz -> 1KHz
module Hz_changer #(
    parameter FCOUNT = 100_000
)(
    input clk,
    input rst,
    output o_clk
);

    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk;

    assign o_clk = r_clk;

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if(r_counter == FCOUNT - 1 ) begin // 1kHz
                r_counter <= 0;
                r_clk <= 1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end
endmodule

// 2. 8 Shift Register
module Shift_Register_8 (
    input clk,
    input rst,
    input i_btn,
    input [7:0] q_reg,
    output reg [7:0] q_next
);

    always @(*) begin
        // q_reg 현재의 상위 7비트를 다음의 하위 7비트에 넣고, 최상위에는 i_btn을 넣어라
        q_next = {i_btn, q_reg[7:1]};
    end
    
endmodule

// 3. 8 input AND Gate
module AND_Gate_8input (
    input [7:0] q_reg,
    output Edge_trigger
);

    assign Edge_trigger = &q_reg;
    
endmodule

// 4. Edge detecter
module Edge_detecter (
    input clk,
    input rst,
    input Edge_trigger,
    output reg edge_detect
);

    always @(posedge clk, posedge rst) begin
        if(rst) edge_detect <= 0;
        else edge_detect <= Edge_trigger;
    end

endmodule

