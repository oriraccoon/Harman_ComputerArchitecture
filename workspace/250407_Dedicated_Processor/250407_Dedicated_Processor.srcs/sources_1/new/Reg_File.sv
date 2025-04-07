`timescale 1ns / 1ps

module Reg_File (
    input logic clk,
    input logic [2:0] readAddr1,
    input logic [2:0] readAddr2,
    input logic [2:0] writeAddr,
    input logic writeEn,
    input logic [7:0] wData,
    output logic [7:0] rData1,
    output logic [7:0] rData2
);

    logic [7:0] mem[0:7];

    always_ff @( posedge clk ) begin : write
        if (writeEn) begin
            mem[writeAddr] <= wData;
        end
    end

    assign rData1 = (readAddr1 == 3'b0) ? 8'b0 : mem[readAddr1];
    assign rData2 = (readAddr2 == 3'b0) ? 8'b0 : mem[readAddr2];

endmodule
