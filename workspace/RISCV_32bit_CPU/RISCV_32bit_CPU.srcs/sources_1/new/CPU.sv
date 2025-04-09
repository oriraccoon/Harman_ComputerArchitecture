
// RISC-V CORE MODULE

module CPU (
    input logic        clk,
    input logic        reset,
    input logic [31:0] instr_code,
    input logic [31:0] rData,

    output logic [31:0] instr_mem_addr,
    output logic        dataWe,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData
);

    logic       regFileWe;
    logic [3:0] alucode;
    logic       aluSrcMuxSel_rs1;
    logic       aluSrcMuxSel_rs2;

    DataPath U_DataPath (.*);
    ControlUnit U_ControlUnit (.*);

endmodule
