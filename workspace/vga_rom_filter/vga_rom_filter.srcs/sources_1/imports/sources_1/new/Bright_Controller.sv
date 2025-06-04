`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/04 13:51:41
// Design Name: 
// Module Name: Bright_Controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Bright_Controller(
    input logic clk,
    input logic reset,
    input logic en,
    input logic [11:0] i_data,
    input logic up_btn,
    input logic down_btn,
    output logic [11:0] o_data 
);

    logic r_up_btn, r_down_btn;

    btn_edge_trigger U_UP_BTN_DEBOUNCE(
        .clk(clk),
        .rst(reset),
        .i_btn(up_btn),
        .o_btn(r_up_btn)
    );
    btn_edge_trigger U_DOWN_BTN_DEBOUNCE(
        .clk(clk),
        .rst(reset),
        .i_btn(down_btn),
        .o_btn(r_down_btn)
    );


    always_ff @( posedge clk ) begin
        if (en) begin
            if (r_up_btn) begin
                case (i_data[11:8])
                    4'b1111: begin
                        o_data[11:8] <= i_data[11:8];
                    end
                    default: begin
                        o_data[11:8] <= i_data[11:8] + 1;
                    end
                endcase
                case (i_data[7:4])
                    4'b1111: begin
                        o_data[7:4] <= i_data[7:4];
                    end
                    4'b1110: begin
                        o_data[7:4] <= i_data[7:4] + 1;
                    end
                    default: begin
                        o_data[7:4] <= i_data[7:4] + 2;
                    end
                endcase
                case (i_data[3:0])
                    4'b1111: begin
                        o_data[3:0] <= i_data[3:0];
                    end
                    default: begin
                        o_data[3:0] <= i_data[3:0] + 1;
                    end
                endcase
            end
            else if (r_down_btn) begin
                case (i_data[11:8])
                    4'b0000: begin
                        o_data[11:8] <= i_data[11:8];
                    end
                    default: begin
                        o_data[11:8] <= i_data[11:8] - 1;
                    end
                endcase
                case (i_data[7:4])
                    4'b0000: begin
                        o_data[7:4] <= i_data[7:4];
                    end
                    4'b0001: begin
                        o_data[7:4] <= i_data[7:4] - 1;
                    end
                    default: begin
                        o_data[7:4] <= i_data[7:4] - 2;
                    end
                endcase
                case (i_data[3:0])
                    4'b0000: begin
                        o_data[3:0] <= i_data[3:0];
                    end
                    default: begin
                        o_data[3:0] <= i_data[3:0] - 1;
                    end
                endcase
            end
            else begin
                o_data <= i_data;
            end
        end
    end
endmodule

