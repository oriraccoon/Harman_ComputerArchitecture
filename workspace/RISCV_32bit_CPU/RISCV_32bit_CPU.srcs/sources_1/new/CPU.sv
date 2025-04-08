
// RISC-V CORE MODULE

module CPU (
    input  logic       clk,
    input  logic       reset,
    input  logic [31:0] instr_code,
    output logic [31:0] instr_mem_addr
);

    logic        regFileWe;
    logic [ 3:0] alucode;

    DataPath U_DataPath (.*);
    ControlUnit U_ControlUnit (.*);

endmodule
