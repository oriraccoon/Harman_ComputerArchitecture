`timescale 1ns / 1ps


module GrayScale_Filter (
    input logic [15:0] data,
    output logic [11:0] RGBdata
);

    logic [4:0] R_data;
    logic [5:0] G_data;
    logic [4:0] B_data;
    logic [13:0] processing_data;
    logic [3:0] Filtered_R_data;
    logic [3:0] Filtered_G_data;
    logic [3:0] Filtered_B_data;
    

    always_comb begin
        R_data = data[15:11];
        G_data = data[10:5];
        B_data = data[4:0];
        processing_data = ((R_data << 6) + (R_data << 3) + (R_data << 2))
                          + ((G_data << 7) + (G_data << 4) + (G_data << 2) + (G_data << 1))
                          + ((B_data << 4) + (B_data << 3) + (B_data << 2) + (B_data << 0));
    end

    always_comb begin
        Filtered_R_data = processing_data[13:10];
        Filtered_G_data = processing_data[13:10];
        Filtered_B_data = processing_data[13:10];
    end

    always_comb begin
        RGBdata = {Filtered_R_data, Filtered_G_data, Filtered_B_data};
    end

endmodule