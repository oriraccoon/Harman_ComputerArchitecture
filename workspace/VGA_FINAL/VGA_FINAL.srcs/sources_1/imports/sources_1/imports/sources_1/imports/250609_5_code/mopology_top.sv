module Mopology_Filter #(
    parameter IMG_WIDTH = 640,
    parameter ADDR_WIDTH = 10  // log2(640) ≈ 10
)(
    input logic clk,
    input logic reset,
    input logic [11:0] i_data,   
    input logic [9:0] x_coor,
    input logic [8:0] y_coor,
    input logic DE,
    output wire moe,
    output logic [11:0] o_data,
    output logic [9:0] w_x_coor,
    output logic [8:0] w_y_coor
);
    logic de_pipe;
    logic de_pipe2;
    // Line buffers using inferred block RAM
    logic [0:0] erode_line1_ram [0:IMG_WIDTH-1];
    logic [0:0] erode_line2_ram [0:IMG_WIDTH-1];

    logic erode_read1, erode_read2;
    logic [0:0] erode_line1_pixel, erode_line2_pixel;
    logic [11:0] i_pipe;
    // 3x3 windows
    logic erode_p11, erode_p12, erode_p13;
    logic erode_p21, erode_p22, erode_p23;
    logic erode_p31, erode_p32, erode_p33;

    integer i, j;
    logic erode_valid_pipeline;
    logic [11:0] erode_o_data_internal;
    logic erode_moe_internal;

    logic [0:0] dilate_line1_ram [0:IMG_WIDTH-1];
    logic [0:0] dilate_line2_ram [0:IMG_WIDTH-1];
    logic [0:0] dilate_line1_pixel, dilate_line2_pixel;

    logic dilate_p11, dilate_p12, dilate_p13;
    logic dilate_p21, dilate_p22, dilate_p23;
    logic dilate_p31, dilate_p32, dilate_p33;

    logic dilate_valid_pipeline;

    logic [9:0] x_buff1, x_buff2, x_buff3;
    logic [8:0] y_buff1, y_buff2, y_buff3;

    assign moe = dilate_valid_pipeline;

    // === Erode ===
    always_ff @( posedge clk ) begin
        if (reset) begin
            x_buff1 <= 0;
            x_buff2 <= 0;
            x_buff3 <= 0;
            y_buff1 <= 0;
            y_buff2 <= 0;
            y_buff3 <= 0;
            w_x_coor <= 0;
            w_y_coor <= 0;
            de_pipe <= 0;
            i_pipe <= 0;
        end 
        else begin
            if (DE) begin
                // shift 2 lines: line2 <= line1, line1 <= new
                erode_line2_ram[x_coor] <= erode_line1_ram[x_coor];
                erode_line1_ram[x_coor] <= i_data[11]; // use MSB as binarized
                x_buff1 <= x_coor;
                x_buff2 <= x_buff1;
                x_buff3 <= x_buff2;
                w_x_coor <= x_buff3;
                y_buff1 <= y_coor;
                y_buff2 <= y_buff1;
                y_buff3 <= y_buff2;
                w_y_coor <= y_buff3;
                de_pipe <= DE;
                i_pipe <= i_data;
            end
        end
    end
    always_ff @(posedge clk) begin
        if (reset) begin
            erode_valid_pipeline <= 3'b0;
            erode_p11 <= 0;
            erode_p12 <= 0;
            erode_p13 <= 0;
            erode_p21 <= 0;
            erode_p22 <= 0;
            erode_p23 <= 0;
            erode_p31 <= 0;
            erode_p32 <= 0;
            erode_p33 <= 0;
        end else if (de_pipe) begin
            case (y_buff1)
                9'd0: begin
                    erode_p13 <= 0;
                    erode_p12 <= erode_p13;
                    erode_p11 <= erode_p12;

                    erode_p23 <= 0;
                    erode_p22 <= erode_p23;
                    erode_p21 <= erode_p22;

                    erode_p33 <= i_pipe[11];
                    erode_p32 <= erode_p33;
                    erode_p31 <= erode_p32;
                end
                9'd1: begin
                    erode_p13 <= 0;
                    erode_p12 <= erode_p13;
                    erode_p11 <= erode_p12;

                    erode_p23 <= erode_line1_ram[x_buff1];
                    erode_p22 <= erode_p23;
                    erode_p21 <= erode_p22;

                    erode_p33 <= i_pipe[11];
                    erode_p32 <= erode_p33;
                    erode_p31 <= erode_p32;
                end 
                default: begin
                    erode_p13 <= erode_line2_ram[x_buff1];
                    erode_p12 <= erode_p13;
                    erode_p11 <= erode_p12;

                    erode_p23 <= erode_line1_ram[x_buff1];
                    erode_p22 <= erode_p23;
                    erode_p21 <= erode_p22;

                    erode_p33 <= i_pipe[11];
                    erode_p32 <= erode_p33;
                    erode_p31 <= erode_p32;
                end
            endcase


            erode_valid_pipeline <= (x_buff1 >= 0 && y_buff1 >= 0);
        end else begin
            erode_valid_pipeline <= 1'b0;
        end
    end


    always_ff @(posedge clk) begin
        if (reset) begin
            erode_o_data_internal <= 12'h000;
            erode_moe_internal <= 1'b0;
        end else if (erode_valid_pipeline) begin
            erode_moe_internal <= 1'b1;
            if (&{erode_p11, erode_p12, erode_p13, erode_p21, erode_p22, erode_p23, erode_p31, erode_p32, erode_p33})
                erode_o_data_internal <= 12'hFFF;
            else
                erode_o_data_internal <= 12'h000;
        end else begin
            erode_moe_internal <= 1'b0;
            erode_o_data_internal <= 12'h000;
        end
    end

    // === Dilate ===
    always_ff @( posedge clk ) begin
        if (reset) begin
            de_pipe2 <= 0;
        end else if (erode_moe_internal) begin
            dilate_line2_ram[x_buff2] <= dilate_line1_ram[x_buff2];
            dilate_line1_ram[x_buff2] <= erode_o_data_internal[11];
            de_pipe2 <= erode_moe_internal;
        end
    end
    always_ff @(posedge clk) begin
        if (reset) begin
            dilate_valid_pipeline <= 3'b0;
            dilate_p13 <= 0;
            dilate_p12 <= 0;
            dilate_p11 <= 0;
            dilate_p23 <= 0;
            dilate_p22 <= 0;
            dilate_p21 <= 0;
            dilate_p33 <= 0;
            dilate_p32 <= 0;
            dilate_p31 <= 0;
        end else if (de_pipe2) begin
            case (y_buff1)
                9'd0: begin
                    dilate_p13 <= 0;
                    dilate_p12 <= dilate_p13;
                    dilate_p11 <= dilate_p12;

                    dilate_p23 <= 0;
                    dilate_p22 <= dilate_p23;
                    dilate_p21 <= dilate_p22;

                    dilate_p33 <= erode_o_data_internal[11];
                    dilate_p32 <= dilate_p33;
                    dilate_p31 <= dilate_p32;
                end
                9'd1: begin
                    dilate_p13 <= 0;
                    dilate_p12 <= dilate_p13;
                    dilate_p11 <= dilate_p12;

                    dilate_p23 <= dilate_line1_ram[x_buff3];
                    dilate_p22 <= dilate_p23;
                    dilate_p21 <= dilate_p22;

                    dilate_p33 <= erode_o_data_internal[11];
                    dilate_p32 <= dilate_p33;
                    dilate_p31 <= dilate_p32;
                end 
                default: begin
                    dilate_p13 <= dilate_line2_ram[x_buff3];
                    dilate_p12 <= dilate_p13;
                    dilate_p11 <= dilate_p12;

                    dilate_p23 <= dilate_line1_ram[x_buff3];
                    dilate_p22 <= dilate_p23;
                    dilate_p21 <= dilate_p22;

                    dilate_p33 <= erode_o_data_internal[11];
                    dilate_p32 <= dilate_p33;
                    dilate_p31 <= dilate_p32;
                end
            endcase


            dilate_valid_pipeline <= (x_buff3 >= 0 && y_buff3 >= 0);
        end else begin
            dilate_valid_pipeline <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            o_data <= 12'h000;
        end else if (dilate_valid_pipeline) begin
            if ({dilate_p11, dilate_p12, dilate_p13, dilate_p21, dilate_p22, dilate_p23, dilate_p31, dilate_p32, dilate_p33})
                o_data <= 12'hFFF;
            else
                o_data <= 12'h000;
        end else begin
            o_data <= 12'h000;
        end
    end

endmodule
