`timescale 1ns / 1ps
// 버튼 누르면 밝기가 증가하는 방식
module BrightController(
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,
    input logic up_btn,
    input logic down_btn,
    output logic [11:0] o_data
);
    logic signed [4:0] bright_offset;

    logic r_up_btn, r_down_btn;

    btn_edge_trigger U_btn_debounce_up (
    .clk(clk), .rst(reset), .i_btn(up_btn),
    .o_btn(r_up_btn)
    );

    btn_edge_trigger U_btn_bedounce_down (
    .clk(clk), .rst(reset), .i_btn(down_btn),
    .o_btn(r_down_btn)
    );

    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            bright_offset <= 0;
        end else begin
            if (r_up_btn && bright_offset < 7) bright_offset <= bright_offset + 1;
            else if(r_down_btn && bright_offset > -8 ) bright_offset <= bright_offset - 1;
            else bright_offset <= bright_offset;
        end
    end

    always_comb begin
        o_data[11:8] = ($signed({1'b0, i_data[11:8]}) + bright_offset > 15) ? 4'd15 : ($signed({1'b0, i_data[11:8]}) + bright_offset < 0) ? 4'd0 : i_data[11:8] + bright_offset;
        o_data[7:4] = ($signed({1'b0, i_data[7:4]}) + bright_offset > 15) ? 4'd15 : ($signed({1'b0, i_data[7:4]}) + bright_offset < 0) ? 4'd0 : i_data[7:4] + bright_offset;
        o_data[3:0] = ($signed({1'b0, i_data[3:0]}) + bright_offset > 15) ? 4'd15 : ($signed({1'b0, i_data[3:0]}) + bright_offset < 0) ? 4'd0 : i_data[3:0] + bright_offset;
    end

endmodule