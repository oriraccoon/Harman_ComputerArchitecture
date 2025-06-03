module Gaussian_Blur (
    input logic clk,
    input logic reset,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic [11:0] i_data,
    input logic de,
    output logic le,
    output logic [11:0] o_data
);

    localparam IMG_WIDTH = 640;

    logic [3:0] R_line_buff1 [0:IMG_WIDTH-1];
    logic [3:0] R_line_buff2 [0:IMG_WIDTH-1];
    logic [3:0] G_line_buff1 [0:IMG_WIDTH-1];
    logic [3:0] G_line_buff2 [0:IMG_WIDTH-1];
    logic [3:0] B_line_buff1 [0:IMG_WIDTH-1];
    logic [3:0] B_line_buff2 [0:IMG_WIDTH-1];
    logic [2:0] pipe_valid;

    logic [3:0] R_gauss_window [0:2][0:2];
    logic [3:0] G_gauss_window [0:2][0:2];
    logic [3:0] B_gauss_window [0:2][0:2];

    logic [8:0] R_sum;
    logic [8:0] G_sum;
    logic [8:0] B_sum;

    integer i;

    localparam integer GAUSS_WINDOW [0:2][0:2] = 
        '{  '{1, 2, 1},
            '{2, 4, 2},
            '{1, 2, 1}
        };

    assign o_data = {R_sum[3:0], G_sum[3:0], B_sum[3:0]};
    assign le = pipe_valid[2];

    always_ff @( posedge clk or posedge reset ) begin : line_pipe
        if (reset) begin
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                R_line_buff1[i] <= 4'b0;
                R_line_buff2[i] <= 4'b0;
                G_line_buff1[i] <= 4'b0;
                G_line_buff2[i] <= 4'b0;
                B_line_buff1[i] <= 4'b0;
                B_line_buff2[i] <= 4'b0;
            end
        end
        else begin
            if (de) begin
                R_line_buff2[x_coor] <= R_line_buff1[x_coor];
                R_line_buff1[x_coor] <= i_data[11:8];
                G_line_buff2[x_coor] <= G_line_buff1[x_coor];
                G_line_buff1[x_coor] <= i_data[7:4];
                B_line_buff2[x_coor] <= B_line_buff1[x_coor];
                B_line_buff1[x_coor] <= i_data[3:0];
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin : window_pipe
        if (reset) begin
            R_gauss_window <= 
                '{  '{0, 0, 0},
                    '{0, 0, 0},
                    '{0, 0, 0}
            };
            G_gauss_window <= 
                '{  '{0, 0, 0},
                    '{0, 0, 0},
                    '{0, 0, 0}
            };
            B_gauss_window <= 
                '{  '{0, 0, 0},
                    '{0, 0, 0},
                    '{0, 0, 0}
            };
            pipe_valid <= 0;
        end
        else begin
            if (de) begin
                R_gauss_window[0][2] <= R_gauss_window[0][1];
                R_gauss_window[0][1] <= R_gauss_window[0][0];
                R_gauss_window[0][0] <= R_line_buff2[x_coor];
                R_gauss_window[1][2] <= R_gauss_window[1][1];
                R_gauss_window[1][1] <= R_gauss_window[1][0];
                R_gauss_window[1][0] <= R_line_buff1[x_coor];
                R_gauss_window[2][2] <= R_gauss_window[2][1];
                R_gauss_window[2][1] <= R_gauss_window[2][0];
                R_gauss_window[2][0] <= i_data[11:8];

                G_gauss_window[0][2] <= G_gauss_window[0][1];
                G_gauss_window[0][1] <= G_gauss_window[0][0];
                G_gauss_window[0][0] <= G_line_buff2[x_coor];
                G_gauss_window[1][2] <= G_gauss_window[1][1];
                G_gauss_window[1][1] <= G_gauss_window[1][0];
                G_gauss_window[1][0] <= G_line_buff1[x_coor];
                G_gauss_window[2][2] <= G_gauss_window[2][1];
                G_gauss_window[2][1] <= G_gauss_window[2][0];
                G_gauss_window[2][0] <= i_data[7:4];

                B_gauss_window[0][2] <= B_gauss_window[0][1];
                B_gauss_window[0][1] <= B_gauss_window[0][0];
                B_gauss_window[0][0] <= B_line_buff2[x_coor];
                B_gauss_window[1][2] <= B_gauss_window[1][1];
                B_gauss_window[1][1] <= B_gauss_window[1][0];
                B_gauss_window[1][0] <= B_line_buff1[x_coor];
                B_gauss_window[2][2] <= B_gauss_window[2][1];
                B_gauss_window[2][1] <= B_gauss_window[2][0];
                B_gauss_window[2][0] <= i_data[3:0];

                pipe_valid <= {pipe_valid[1:0], (x_coor >= 2 && y_coor >= 2)};
            end
            else begin
                pipe_valid <= {pipe_valid[1:0], 1'b0};
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin : window_out
        if (reset) begin
            R_sum <= 9'b0;
            G_sum <= 9'b0;
            B_sum <= 9'b0;
        end
        else begin
            if (pipe_valid[2]) begin
                R_sum <=  ((R_gauss_window[0][2] << GAUSS_WINDOW[0][2]) + 
                        (R_gauss_window[0][1] << GAUSS_WINDOW[0][1]) +
                        (R_gauss_window[0][0] << GAUSS_WINDOW[0][0]) +
                        (R_gauss_window[1][2] << GAUSS_WINDOW[1][2]) +
                        (R_gauss_window[1][1] << GAUSS_WINDOW[1][1]) +
                        (R_gauss_window[1][0] << GAUSS_WINDOW[1][0]) +
                        (R_gauss_window[2][2] << GAUSS_WINDOW[2][2]) +
                        (R_gauss_window[2][1] << GAUSS_WINDOW[2][1]) +
                        (R_gauss_window[2][0] << GAUSS_WINDOW[2][0])) >> 4;

                G_sum <=  ((G_gauss_window[0][2] << GAUSS_WINDOW[0][2]) + 
                        (G_gauss_window[0][1] << GAUSS_WINDOW[0][1]) +
                        (G_gauss_window[0][0] << GAUSS_WINDOW[0][0]) +
                        (G_gauss_window[1][2] << GAUSS_WINDOW[1][2]) +
                        (G_gauss_window[1][1] << GAUSS_WINDOW[1][1]) +
                        (G_gauss_window[1][0] << GAUSS_WINDOW[1][0]) +
                        (G_gauss_window[2][2] << GAUSS_WINDOW[2][2]) +
                        (G_gauss_window[2][1] << GAUSS_WINDOW[2][1]) +
                        (G_gauss_window[2][0] << GAUSS_WINDOW[2][0])) >> 4;

                B_sum <=  ((B_gauss_window[0][2] << GAUSS_WINDOW[0][2]) + 
                        (B_gauss_window[0][1] << GAUSS_WINDOW[0][1]) +
                        (B_gauss_window[0][0] << GAUSS_WINDOW[0][0]) +
                        (B_gauss_window[1][2] << GAUSS_WINDOW[1][2]) +
                        (B_gauss_window[1][1] << GAUSS_WINDOW[1][1]) +
                        (B_gauss_window[1][0] << GAUSS_WINDOW[1][0]) +
                        (B_gauss_window[2][2] << GAUSS_WINDOW[2][2]) +
                        (B_gauss_window[2][1] << GAUSS_WINDOW[2][1]) +
                        (B_gauss_window[2][0] << GAUSS_WINDOW[2][0])) >> 4;
            end
        end
    end


endmodule