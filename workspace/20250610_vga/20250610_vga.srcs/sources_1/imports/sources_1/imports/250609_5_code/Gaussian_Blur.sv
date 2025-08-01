module Gaussian_Blur (
    input logic clk,
    input logic reset,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic [3:0] i_data,
    input logic de,
    input logic up_btn,
    input logic down_btn,
    output logic le,
    output logic [11:0] o_data
);

    localparam IMG_WIDTH = 640;

    logic [3:0] line_buff1 [0:IMG_WIDTH-1];
    logic [3:0] line_buff2 [0:IMG_WIDTH-1];
    logic [2:0] pipe_valid;

    logic [3:0] gauss_window [0:2][0:2];
    logic [11:0] CONTRAST_RGB444_data;

    logic [8:0] sum;

    integer i;

    localparam integer GAUSS_WINDOW [0:2][0:2] = 
        '{  '{0, 1, 0},
            '{1, 2, 1},
            '{0, 1, 0}
        };

    Contrast U_CONT(
        .clk(clk),
        .reset(reset),
        .up_btn(up_btn),
        .down_btn(down_btn),
        .x_pixel(x_coor),
        .y_pixel(y_coor),
        .rgb({sum[3:0], sum[3:0], sum[3:0]}),
        .red_port(CONTRAST_RGB444_data[11:8]),
        .green_port(CONTRAST_RGB444_data[7:4]),
        .blue_port(CONTRAST_RGB444_data[3:0])
    );

    assign o_data = {CONTRAST_RGB444_data};
    assign le = pipe_valid[2];

    always_ff @( posedge clk or posedge reset ) begin : line_pipe
        if (reset) begin
            line_buff1[i] <= '{default: 0};
            line_buff2[i] <= '{default: 0};
        end
        else begin
            if (de) begin
                line_buff2[x_coor] <= line_buff1[x_coor];
                line_buff1[x_coor] <= i_data;
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin : window_pipe
        if (reset) begin
            gauss_window <= 
                '{  '{0, 0, 0},
                    '{0, 0, 0},
                    '{0, 0, 0}
            };
            pipe_valid <= 0;
        end
        else begin
            if (de) begin
                gauss_window[0][2] <= gauss_window[0][1];
                gauss_window[0][1] <= gauss_window[0][0];
                gauss_window[0][0] <= line_buff2[x_coor];
                gauss_window[1][2] <= gauss_window[1][1];
                gauss_window[1][1] <= gauss_window[1][0];
                gauss_window[1][0] <= line_buff1[x_coor];
                gauss_window[2][2] <= gauss_window[2][1];
                gauss_window[2][1] <= gauss_window[2][0];
                gauss_window[2][0] <= i_data;

                pipe_valid <= {pipe_valid[1:0], (x_coor >= 2 && y_coor >= 2)};
            end
            else begin
                pipe_valid <= {pipe_valid[1:0], 1'b0};
            end
        end
    end

    always_ff @( posedge clk or posedge reset ) begin : window_out
        if (reset) begin
            sum <= 9'b0;
        end
        else begin
            if (pipe_valid[2]) begin
                sum <=  ((gauss_window[0][2] << GAUSS_WINDOW[0][2]) + 
                        (gauss_window[0][1] << GAUSS_WINDOW[0][1]) +
                        (gauss_window[0][0] << GAUSS_WINDOW[0][0]) +
                        (gauss_window[1][2] << GAUSS_WINDOW[1][2]) +
                        (gauss_window[1][1] << GAUSS_WINDOW[1][1]) +
                        (gauss_window[1][0] << GAUSS_WINDOW[1][0]) +
                        (gauss_window[2][2] << GAUSS_WINDOW[2][2]) +
                        (gauss_window[2][1] << GAUSS_WINDOW[2][1]) +
                        (gauss_window[2][0] << GAUSS_WINDOW[2][0])) >> 4;
            end
        end
    end


endmodule