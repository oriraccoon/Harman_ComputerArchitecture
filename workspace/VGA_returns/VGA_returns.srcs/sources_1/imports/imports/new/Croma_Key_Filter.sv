module Second_Filter(
	input logic CROMA_KEY,
	// input logic EDGE_DATA,
	input logic BLUR_DATA,
	input logic [11:0] b_data,
	input logic [11:0] i_data,
	output logic [11:0] o_data
);

	logic [11:0] Croma_Key_data;
	logic [11:0] edge_data;

	always_comb begin
		case ({CROMA_KEY, BLUR_DATA})
			2'b00: o_data = i_data;
			2'b10: o_data = Croma_Key_data;
			2'b01: o_data = b_data;
			default: o_data = i_data;
		endcase
	end

	Croma_Key_Filter U_CROMA_KEY (
		.CROMA_KEY(CROMA_KEY),
		.data(i_data),
		.Croma_Key_data(Croma_Key_data)
	);

	// EDGE_DATA_Filter U_EDGE_DATA (
	// 	.EDGE_DATA(EDGE_DATA),
	// 	.data(i_data),
	// 	.edge_data(edge_data)
	// );

endmodule

module Croma_Key_Filter (
    input logic CROMA_KEY,
    input logic [11:0] data,
    output logic [11:0] Croma_Key_data
);

    always_comb begin : Data_Processing
        Croma_Key_data = (CROMA_KEY == 1) ? /*((data[11:8] <= 4) && (data[7:4] >= 9) && (data[3:0] <= 4))*/((data[11:8] <= 1) && (data[7:4] <= 1) && (data[3:0] <= 1)) ? 12'hF0F : data : data;
    end

endmodule

module EDGE_DATA_Filter (
		input logic EDGE_DATA,
		input logic [11:0] data,
		output logic [11:0] edge_data
);

		logic [11:0] processing_data;

		always_comb begin
			edge_data = (EDGE_DATA==1) ? processing_data : data;
		end

endmodule
