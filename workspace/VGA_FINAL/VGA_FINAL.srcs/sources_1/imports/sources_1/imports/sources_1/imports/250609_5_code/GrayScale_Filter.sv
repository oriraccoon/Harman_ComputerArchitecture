`timescale 1ns / 1ps


module GrayScale_Filter (
    input logic [11:0] data,
    output logic [11:0] RGBdata
);

    logic [3:0] R_data;
    logic [3:0] G_data;
    logic [3:0] B_data;
    logic [11:0] processing_data;
    logic [3:0] Filtered_data;
    

    always_comb begin
        R_data = data[11:8];
        G_data = data[7:4];
        B_data = data[3:0];
        processing_data = ((R_data << 6) + (R_data << 3) + (R_data << 2))
                          + ((G_data << 7) + (G_data << 4) + (G_data << 2) + (G_data << 1))
                          + ((B_data << 4) + (B_data << 3) + (B_data << 2) + (B_data << 0));
    end

    always_comb begin
        Filtered_data = processing_data[11:8];
    end

    always_comb begin
        RGBdata = {Filtered_data, Filtered_data, Filtered_data};
    end

endmodule

module GrayScale_Filter_4bit (
    input logic [11:0] data,
    output logic [3:0] RGBdata
);

    logic [3:0] R_data;
    logic [3:0] G_data;
    logic [3:0] B_data;
    logic [11:0] processing_data;
    

    always_comb begin
        R_data = data[11:8];
        G_data = data[7:4];
        B_data = data[3:0];
        processing_data = ((R_data << 6) + (R_data << 3) + (R_data << 2))
                          + ((G_data << 7) + (G_data << 4) + (G_data << 2) + (G_data << 1))
                          + ((B_data << 4) + (B_data << 3) + (B_data << 2) + (B_data << 0));
    end

    always_comb begin
        RGBdata = processing_data[11:8];
    end

endmodule