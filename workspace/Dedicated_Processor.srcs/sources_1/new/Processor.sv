module Dedicate_Processor(
    input logic clk,
    input logic rst,
    output logic [7:0] outvalue
    );

    logic altb, aen, asel, outbuf;

    Control_Unit U_Control_Unit(
        .clk(clk),
        .rst(rst),
        .altb(altb),

        .asel(asel),
        .aen(aen),
        .outbuf(outbuf)
    );

    Data_Path U_Data_Path(
        .clk(clk),
        .rst(rst),
        .asel(asel),
        .aen(aen),
        .outbuf(outbuf),

        .altb(altb),
        .outport(outvalue)
    );

endmodule
