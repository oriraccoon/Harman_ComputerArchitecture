module Gaussian_Blur (
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,
    output logic [11:0] o_data
);

    logic [3:0] Gauss_window [0:2][0:2];

    always_ff @( posedge clk or posedge reset ) begin
        if (reset) begin
            Gauss_window = {{1, 2, 1}, {2, 4, 2}, {1, 2, 1}};
        end
        
    end



endmodule