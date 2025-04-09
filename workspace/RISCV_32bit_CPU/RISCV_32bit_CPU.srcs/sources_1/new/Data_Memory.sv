module Data_Memory (
    input logic        clk,
    input logic        dataWe,
    input logic [31:0] dataAddr,
    input logic [31:0] dataWData,

    output logic [31:0] rData
);

    logic [31:0] mem [0:9];
    initial begin
        for (int i = 0; i < 10; i++) begin
            mem[i] = 101652 + i;
        end
    end

    always_ff @( posedge clk ) begin
        if (dataWe) begin
            mem[dataAddr[31:2]] <= dataWData;
        end
    end

    assign rData = mem[dataAddr[31:2]];


endmodule
