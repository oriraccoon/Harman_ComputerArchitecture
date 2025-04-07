module Dedicate_Processor(
    input logic clk,
    input logic rst,
    input logic [3:0] repeat_num,
    input logic [2:0] start_num,
    output logic [7:0] outvalue
    );

    logic altb, aen, asel, outbuf;

    Control_Unit U_Control_Unit(
        .clk(clk),
        .rst(rst),
        .altb(altb),
        .start_trig(start_trig),

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
        .repeat_num2(repeat_num),
        .start_num(start_num),

        .altb(altb),
        .outport(outvalue),
        .start_trig(start_trig)
    );

endmodule
