module Sobel_Filter #(
    parameter THRESHOLD = 8  
)(
    input  logic       clk,
    input  logic       reset,
    input  logic [11:0] gray_in,
    input  logic [9:0] x_coor,
    input  logic [8:0] y_coor,
    input  logic       de,
    output logic [11:0] sobel_out,
    output logic [11:0] scharr_out,
    output logic [11:0] s_sobel, s_scharr
);
    localparam IMG_WIDTH = 640;


    logic [3:0] line_buffer_1[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_2[0:IMG_WIDTH-1];

    logic [3:0] p11, p12, p13;
    logic [3:0] p21, p22, p23;
    logic [3:0] p31, p32, p33;

    logic [2:0] valid_pipeline;

    logic signed [10:0] gx, gy;
    logic signed [11:0] c_gx, c_gy;
    logic [10:0] mag;
    logic [11:0] c_mag;
    logic [3:0] cliping_sum, c_cliping_sum;

    integer i;

    assign cliping_sum = (mag >> 3);
    assign c_cliping_sum = (c_mag >> 5);
    assign s_sobel = {cliping_sum, cliping_sum, cliping_sum};
    assign s_scharr = {c_cliping_sum, c_cliping_sum, c_cliping_sum};


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line_buffer_1[i] <= 0;
                line_buffer_2[i] <= 0;
            end
        end else if (de) begin
            line_buffer_2[x_coor] <= line_buffer_1[x_coor];
            line_buffer_1[x_coor] <= gray_in[3:0];
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_pipeline <= 0;
        end else if (de) begin
            p13 <= line_buffer_2[x_coor];
            p12 <= p13;
            p11 <= p12;

            p23 <= line_buffer_1[x_coor];
            p22 <= p23;
            p21 <= p22;

            p33 <= gray_in[3:0];
            p32 <= p33;
            p31 <= p32;

            valid_pipeline <= {
                valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)
            };
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            gx        <= 0;
            gy        <= 0;
            mag       <= 0;
            sobel_out <= 0;
            c_gx        <= 0;
            c_gy        <= 0;
            c_mag       <= 0;
            scharr_out <= 0;
        end else if (valid_pipeline[2]) begin

            gx <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
            gy <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13);
            mag <= (gx[10] ? -gx : gx) + (gy[10] ? -gy : gy);
            sobel_out <= (mag > THRESHOLD) ? 12'hFFF : 12'h0;


            c_gx <= (((p13<<1)+p13) + ((p23 << 3) + (p23 << 1)) + ((p33<<1)+p33)) - (((p11<<1)+p11) + ((p21 << 3) + (p21 << 1)) + ((p31<<1)+p31));
            c_gy <= (((p31<<1)+p31) + ((p32 << 3) + (p32 << 1)) + ((p33<<1)+p33)) - (((p11<<1)+p11) + ((p12 << 3) + (p12 << 1)) + ((p13<<1)+p13));
            c_mag <= (c_gx[11] ? -c_gx : c_gx) + (c_gy[11] ? -c_gy : c_gy);
            scharr_out <= (c_mag > (THRESHOLD+2)) ? 12'hFFF : 12'h0;
            
        end else begin
            sobel_out <= 0;
            scharr_out <= 0;
        end
    end

endmodule