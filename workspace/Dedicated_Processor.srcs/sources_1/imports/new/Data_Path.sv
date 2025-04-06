module Data_Path(
    input logic clk,
    input logic rst,
    input logic asel,
    input logic aen,
    input logic outbuf,
    input logic [3:0] repeat_num2,
    input logic [2:0] start_num,

    output logic altb,
    output logic [7:0] outport
    );

    logic [7:0] win, reg_out, buffer_data, sum, repeat_num;
    
    assign outport = buffer_data;

    Mux2x1 U_Mux2x1(
        .a(start_num),
        .b(sum),
        .asel(asel),
        .win(win)
    );

    Register U_Register(
        .clk(clk),
        .rst(rst),
        .aen(aen),
        .invalue(win),
        .outvalue(reg_out),
        .outrepeat(repeat_num)
    );

    Adder U_Adder(
        .a(reg_out),
        .b(repeat_num),
        .sum(sum)
    );

    Comparator U_Comparator(
        .a(repeat_num),
        .b(repeat_num2),
        .altb(altb)
    );

    Buffer U_Buffer(
        .clk(clk),
        .rst(rst),
        .outbuf(outbuf),
        .a(reg_out),
        .buffer_data(buffer_data)
    );

endmodule

module Mux2x1 (
    input logic [2:0] a,
    input logic [7:0] b,
    input logic asel,
    output logic [7:0] win
);
    always @(*) begin
        case (asel)
            0: win = a;
            1: win = b;
        endcase
    end
endmodule

module Register (
    input logic clk,
    input logic rst,
    input logic aen,
    input logic [7:0] invalue,
    output logic [7:0] outvalue,
    output logic [7:0] outrepeat
);

    always_ff @( posedge clk or posedge rst ) begin : Reg_FF
        if(rst) begin
            outvalue <= 0;
            outrepeat <= 0;
        end
        else begin
            if(aen) begin
                outvalue <= invalue;
                outrepeat <= outrepeat + 1;
            end
        end
    end

endmodule

module Adder (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] sum
);

    assign sum = a + b;
    
endmodule


module Comparator (
    input logic [3:0] a,
    input logic [3:0] b,
    output logic altb
);
    assign altb = (a <= b) ? 1 : 0;

endmodule

module Buffer (
    input logic clk,
    input logic rst,
    input logic outbuf,
    input logic [7:0] a,
    output logic [7:0] buffer_data
);

    always @(posedge clk or posedge rst) begin
        if(rst) buffer_data <= 0;
        else begin
            if(outbuf) buffer_data <= a;
            else buffer_data <= buffer_data;
        end
    end

endmodule