module Gaussian_Blur (
    input logic clk,
    input logic reset,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic [3:0] i_data,
    output logic [11:0] o_data
);

    logic [3:0] G_cal [0:2][0:320];
    logic [11:0] sum;

    localparam integer GAUSS_WINDOW [0:2][0:2] = 
        '{  '{1, 2, 1},
            '{2, 4, 2},
            '{1, 2, 1}
        };


    always_comb begin
        casex ({x_coor, y_coor})
            {10'd0, 9'dx}: begin
                
            end
            {10'dx, 9'd0}: begin
                
            end
        endcase
    end


endmodule