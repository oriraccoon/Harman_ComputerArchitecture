module Data_Path(
    input logic clk,
    input logic rst,
    input logic asel,
    input logic aen,
    input logic outbuf,

    output logic altb,
    output logic [7:0] outport
    );

    logic [7:0] win, reg_out, buffer_data, sum;

    assign outport = buffer_data;

    Mux2x1 U_Mux2x1(
        .a(0),
        .b(sum),
        .asel(asel),
        .win(win)
    );

    Register U_Register(
        .clk(clk),
        .rst(rst),
        .aen(aen),
        .invalue(win),
        .outvalue(reg_out)
    );

    Adder U_Adder(
        .a(reg_out),
        .b(reg_out + 1),
        .sum(sum)
    );

    Comparator U_Comparator(
        .a(reg_out),
        .b(4'd11),
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
    input logic [7:0] a,
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
    output logic [7:0] outvalue
);

    always_ff @( posedge clk or posedge rst ) begin : Reg_FF
        if(rst) begin
            outvalue <= 0;
        end
        else begin
            if(aen) begin
                outvalue <= invalue;
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
    input logic [7:0] a,
    input logic [7:0] b,
    output logic altb
);
    assign altb = (a < b);

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