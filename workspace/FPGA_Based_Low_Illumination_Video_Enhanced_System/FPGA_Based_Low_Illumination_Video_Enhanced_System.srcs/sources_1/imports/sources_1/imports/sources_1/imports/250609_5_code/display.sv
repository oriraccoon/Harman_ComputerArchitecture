`timescale 1ns / 1ps


module final_display (
    input  logic [3:0] red_port_org,
    input  logic [3:0] green_port_org,
    input  logic [3:0] blue_port_org,
    input  logic [3:0] red_port_after,
    input  logic [3:0] green_port_after,
    input  logic [3:0] blue_port_after,
    input  logic [3:0] red_port_hist,
    input  logic [3:0] green_port_hist,
    input  logic [3:0] blue_port_hist,
    input  logic [3:0] red_port_hist_org,
    input  logic [3:0] green_port_hist_org,
    input  logic [3:0] blue_port_hist_org,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    input              DE1,
    input              DE2,
    input              DE3,
    input              DE4,
    input              DEhistFont
);

    always_comb begin
        if (DE1) begin
            {red_port, green_port, blue_port} = {red_port_after, green_port_after, blue_port_after};
        end else if (DE2) begin
            {red_port, green_port, blue_port} = {red_port_hist, green_port_hist, blue_port_hist};
        end else if (DE3) begin
            {red_port, green_port, blue_port} = {red_port_org, green_port_org, blue_port_org};
        end else if (DE4) begin
            {red_port, green_port, blue_port} = {red_port_hist_org, green_port_hist_org, blue_port_hist_org};
        end else begin
            {red_port, green_port, blue_port} = 16'bz;
        end
    end
endmodule
