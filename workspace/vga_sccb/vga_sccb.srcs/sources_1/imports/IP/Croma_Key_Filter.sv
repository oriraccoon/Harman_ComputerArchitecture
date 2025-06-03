module Croma_Key_Filter (
    input logic CROMA_KEY,
    input logic [11:0] data,
    output logic [11:0] CROMA_RGB444_data
);

    always_comb begin : Data_Processing
        CROMA_RGB444_data = (CROMA_KEY == 1) ? ((data[11:8] <= 4) && (data[7:4] >= 9) && (data[3:0] <= 4)) ? 12'hF0F : data : data;
    end

endmodule

