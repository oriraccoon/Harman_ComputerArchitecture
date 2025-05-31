module Croma_Key_Filter (
    input logic [11:0] data,
    output logic [11:0] Croma_Key_data
);

    always_comb begin : Data_Processing
        Croma_Key_data = ((data[11:8] <= 4) && (data[7:4] >= 9) && (data[3:0] <= 4)) ? 12'hF0F : data;
    end

endmodule