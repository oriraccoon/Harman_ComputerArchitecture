module mopology_top (
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic de,
    output logic [11:0] o_data
);
    
    logic [11:0] w_data;
    logic oe;

    mopology_erode U_ERODE (
        .*,
        .o_data(w_data)
    );
    mopology_dilate U_DILATE (
        .*,
        .de(oe),
        .i_data(w_data)
    );

endmodule


module mopology_erode #(
    parameter IMG_WIDTH = 640
)(
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic de,
    output logic oe,
    output logic [11:0] o_data
);

    logic [0:IMG_WIDTH-1] line1, line2;
    logic p11, p12, p13;
    logic p21, p22, p23;
    logic p31, p32, p33;

    logic [2:0] valid_pipeline;

    always_ff @(posedge clk) begin
        if (reset) begin
            line1 <= 0;
            line2 <= 0;
        end else if (de) begin
            line2[x_coor] <= line1[x_coor];
            line1[x_coor] <= i_data[11];
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_pipeline <= 0;
        end else if (de) begin
            p13 <= line2[x_coor];
            p12 <= p13;
            p11 <= p12;

            p23 <= line1[x_coor];
            p22 <= p23;
            p21 <= p22;

            p33 <= i_data[11];
            p32 <= p33;
            p31 <= p32;

            valid_pipeline <= {valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)};
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            o_data <= 0;
            oe <= 0;
        end else if (valid_pipeline[2]) begin
            oe <= 1;
            if (p11 & p12 & p13 & p21 & p22 & p23 & p31 & p32 & p33)
                o_data <= 12'hFFF;
            else
                o_data <= 12'h000;
        end else begin
            oe <= 0;
            o_data <= 0;
        end
    end
endmodule

module mopology_dilate #(
    parameter IMG_WIDTH = 640
)(
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic de,
    output logic [11:0] o_data
);

    logic [0:IMG_WIDTH-1] line1, line2;
    logic p11, p12, p13;
    logic p21, p22, p23;
    logic p31, p32, p33;

    logic [2:0] valid_pipeline;

    always_ff @(posedge clk) begin
        if (reset) begin
            line1 <= 0;
            line2 <= 0;
        end else if (de) begin
            line2[x_coor] <= line1[x_coor];
            line1[x_coor] <= i_data[11];
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_pipeline <= 0;
        end else if (de) begin
            p13 <= line2[x_coor];
            p12 <= p13;
            p11 <= p12;

            p23 <= line1[x_coor];
            p22 <= p23;
            p21 <= p22;

            p33 <= i_data[11];
            p32 <= p33;
            p31 <= p32;

            valid_pipeline <= {valid_pipeline[1:0], (x_coor >= 2 && y_coor >= 2)};
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            o_data <= 0;
        end else if (valid_pipeline[2]) begin
            if (p11 | p12 | p13 | p21 | p22 | p23 | p31 | p32 | p33)
                o_data <= 12'hFFF;
            else
                o_data <= 12'h000;
        end else begin
            o_data <= 0;
        end
    end

endmodule
