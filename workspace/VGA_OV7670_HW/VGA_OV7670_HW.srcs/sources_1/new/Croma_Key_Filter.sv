module Second_Filter(
	input logic CROMA_KEY,
	input logic SOBEL,
	input logic [11:0] i_data,
	output logic [11:0] o_data
);

	logic [11:0] Croma_Key_data;
	logic [11:0] Sobel_data;

	always_comb begin
		case ({CROMA_KEY, SOBEL})
			2'b00: o_data = i_data;
			2'b10: o_data = Croma_Key_data;
			2'b01: o_data = Sobel_data;
			default: o_data = i_data;
		endcase
	end

	Croma_Key_Filter U_CROMA_KEY (
		.CROMA_KEY(CROMA_KEY),
		.data(i_data),
		.Croma_Key_data(Croma_Key_data)
	);

	Sobel_Filter U_SOBEL (
		.SOBEL(SOBEL),
		.data(i_data),
		.Sobel_data(Sobel_data)
	);

endmodule

module Croma_Key_Filter (
    input logic CROMA_KEY,
    input logic [11:0] data,
    output logic [11:0] Croma_Key_data
);

    always_comb begin : Data_Processing
        Croma_Key_data = (CROMA_KEY == 1) ? ((data[11:8] <= 4) && (data[7:4] >= 9) && (data[3:0] <= 4)) ? 12'hF0F : data : data;
    end

endmodule

module Sobel_Filter (
		input logic SOBEL,
		input logic [11:0] data,
		output logic [11:0] Sobel_data
);

		logic [11:0] processing_data;

		always_comb begin
			Sobel_data = (SOBEL==1) ? processing_data : data;
		end

endmodule
