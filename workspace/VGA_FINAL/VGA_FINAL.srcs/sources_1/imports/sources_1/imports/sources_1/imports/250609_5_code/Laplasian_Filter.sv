module Laplasian_Filter #(
    parameter THRESHOLD = 4
)(
    input logic clk,
    input logic reset,
    input logic de,
    output logic laen,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic [11:0] g_data,
    output logic [11:0] l_data,
    output logic [11:0] ls_data,
    output logic [9:0] w_x_coor,
    output logic [8:0] w_y_coor
);

    localparam IMG_WIDTH = 640;

    logic [3:0] line_buff1 [0:IMG_WIDTH-1];
    logic [3:0] line_buff2 [0:IMG_WIDTH-1];
    logic pipe_valid;
    logic de_pipe;
    logic [11:0] g_pipe;

    logic [3:0] Laplacian_window [0:2][0:2];

    logic signed [9:0] Laplacian_sum;
    logic [8:0] abs_sum;
    logic [3:0] cliping_sum;

    logic [9:0] x_buff1;
    logic [8:0] y_buff1;
    integer i;
    assign abs_sum = (Laplacian_sum < 0) ? -Laplacian_sum : Laplacian_sum;
    assign cliping_sum = (abs_sum >> 3);
    assign l_data = {(cliping_sum > THRESHOLD) ? 12'hFFF : 12'h0};
    assign ls_data = {cliping_sum, cliping_sum, cliping_sum};
    assign laen = pipe_valid;

    always_ff @( posedge clk or posedge reset ) begin : line_pipe
        if (reset) begin
            w_x_coor <= 0;
            w_y_coor <= 0;
            x_buff1 <= 0;
            y_buff1 <= 0;
            de_pipe <= 0;
            g_pipe <= 0;
        end
        else begin
            if (de) begin
                line_buff2[x_coor] <= line_buff1[x_coor];
                line_buff1[x_coor] <= g_data[3:0];
                w_x_coor <= x_buff1;
                w_y_coor <= y_buff1;
                x_buff1 <= x_coor;
                y_buff1 <= y_coor;
                de_pipe <= de;
                g_pipe <= g_data;
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin : window_pipe
        if (reset) begin
            Laplacian_window <= 
                '{  '{0, 0, 0},
                    '{0, 0, 0},
                    '{0, 0, 0}
            };
            pipe_valid <= 0;
        end
        else begin
            if (de_pipe) begin
            case (y_buff1)
                9'd0: begin
                    Laplacian_window[0][2] <= Laplacian_window[0][1];
                    Laplacian_window[0][1] <= Laplacian_window[0][0];
                    Laplacian_window[0][0] <= 0;
                    Laplacian_window[1][2] <= Laplacian_window[1][1];
                    Laplacian_window[1][1] <= Laplacian_window[1][0];
                    Laplacian_window[1][0] <= 0;
                    Laplacian_window[2][2] <= Laplacian_window[2][1];
                    Laplacian_window[2][1] <= Laplacian_window[2][0];
                    Laplacian_window[2][0] <= g_pipe[3:0];
                end
                9'd1: begin
                    Laplacian_window[0][2] <= Laplacian_window[0][1];
                    Laplacian_window[0][1] <= Laplacian_window[0][0];
                    Laplacian_window[0][0] <= 0;
                    Laplacian_window[1][2] <= Laplacian_window[1][1];
                    Laplacian_window[1][1] <= Laplacian_window[1][0];
                    Laplacian_window[1][0] <= line_buff1[x_buff1];
                    Laplacian_window[2][2] <= Laplacian_window[2][1];
                    Laplacian_window[2][1] <= Laplacian_window[2][0];
                    Laplacian_window[2][0] <= g_pipe[3:0];
                end 
                default: begin
                    Laplacian_window[0][2] <= Laplacian_window[0][1];
                    Laplacian_window[0][1] <= Laplacian_window[0][0];
                    Laplacian_window[0][0] <= line_buff2[x_buff1];
                    Laplacian_window[1][2] <= Laplacian_window[1][1];
                    Laplacian_window[1][1] <= Laplacian_window[1][0];
                    Laplacian_window[1][0] <= line_buff1[x_buff1];
                    Laplacian_window[2][2] <= Laplacian_window[2][1];
                    Laplacian_window[2][1] <= Laplacian_window[2][0];
                    Laplacian_window[2][0] <= g_pipe[3:0];
                end
            endcase

                pipe_valid <= (x_buff1 >= 0 && y_buff1 >= 0);
            end
            else begin
                pipe_valid <= 1'b0;
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin : window_out
        if (reset) begin
            Laplacian_sum <= 9'b0;
        end
        else begin
            if (pipe_valid) begin
                Laplacian_sum <= ((Laplacian_window[0][2]) + 
                                  (Laplacian_window[0][1]) +
                                  (Laplacian_window[0][0]) +
                                  (Laplacian_window[1][2]) -
                                  ( (Laplacian_window[1][1] << 3) ) +
                                  (Laplacian_window[1][0]) +
                                  (Laplacian_window[2][2]) +
                                  (Laplacian_window[2][1]) +
                                  (Laplacian_window[2][0]));
            end
        end
    end

endmodule