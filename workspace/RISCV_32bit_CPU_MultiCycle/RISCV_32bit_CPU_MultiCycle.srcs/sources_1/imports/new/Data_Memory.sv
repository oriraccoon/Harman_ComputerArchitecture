module Data_Memory (
    input logic        clk,
    input logic        dataWe,
    input logic [31:0] instr_code,
    input logic [31:0] dataAddr,
    input logic [31:0] dataWData,

    output logic [31:0] rData
);

    logic [31:0] mem [0:63];
    /*initial begin
        for (int i = 0; i < 6; i++) begin
            mem[i] = 101652 + i;
        end
        mem[6] = 32'b01010101_01010101_01010101_11010101;
    end
*/
    always_ff @( posedge clk ) begin
        if (dataWe) begin
            if (instr_code[6:0] == 7'b0100011 && instr_code[14:12] == 000) begin
                mem[dataAddr[31:2]][7:0] <= dataWData[7:0];
            end
            else if (instr_code[6:0] == 7'b0100011 && instr_code[14:12] == 001) begin
                mem[dataAddr[31:2]][15:0] <= dataWData[15:0];
            end
            else mem[dataAddr[31:2]] <= dataWData;
        end
    end

    assign rData = mem[dataAddr[31:2]];


endmodule
