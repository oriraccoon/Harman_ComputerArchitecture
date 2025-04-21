
// RISC-V CORE MODULE

module CPU (
    input logic        clk,
    input logic        rst,
    input logic [31:0] instr_code,
    input logic [31:0] rData,

    output logic [31:0] instr_mem_addr,
    output logic        dataWe,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData
);

    logic       regFileWe;
    logic [3:0] alucode;
    logic [2:0] Lcode;
    logic [2:0] wdSrcMuxSel;
    logic       aluSrcMuxSel;
    logic [1:0] pcSrcMuxSel;
    logic       pcen;

    DataPath U_DataPath (.*);
    ControlUnit U_ControlUnit (.*);

endmodule
