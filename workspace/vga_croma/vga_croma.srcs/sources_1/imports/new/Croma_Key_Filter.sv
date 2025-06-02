module Second_Filter(
	input logic CROMA_KEY,
	input logic LAPLA_DATA,
	input logic BLUR_DATA,
	input logic [11:0] l_data,
	input logic [11:0] b_data,
	input logic [11:0] i_data,
	output logic [11:0] o_data
);

	logic [11:0] Croma_Key_data;

	always_comb begin
		case ({CROMA_KEY, BLUR_DATA, LAPLA_DATA})
			3'b000: o_data = i_data;
			3'b100: o_data = Croma_Key_data;
			3'b010: o_data = b_data;
			3'b001: o_data = l_data;
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