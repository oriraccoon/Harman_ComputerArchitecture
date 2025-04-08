module Data_Memory (
    input  logic       clk,
    input  logic [31:0] readAddr,
    input  logic [31:0] writeAddr,
    input  logic       writeEn,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    
endmodule