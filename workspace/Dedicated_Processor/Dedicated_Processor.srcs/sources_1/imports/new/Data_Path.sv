module Data_Path(
    input logic clk,
    input logic rst,
    input logic asel,
    input logic aen,
    input logic outbuf,
    input logic [3:0] repeat_num2,
    input logic [2:0] start_num,

    output logic altb,
    output logic [7:0] outport,
    output logic start_trig
    );

    logic [7:0] win, reg_out, buffer_data, sum, add_num;
    logic [3:0] repeat_num;
    
    assign outport = buffer_data;

    assign repeat_num = start_trig ? 0 : repeat_num;
    assign add_num = start_trig ? start_num : add_num;

    Start_signal U_Start_signal(
        .clk(clk),
        .rst(rst),
        .start_num(start_num),
        .start_trig(start_trig)
    );

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
        .addin(add_num),
        .invalue(win),
        .outvalue(reg_out),
        .outrepeat(repeat_num),
        .add_num(add_num)
    );

    Adder U_Adder(
        .a(reg_out),
        .b(add_num),
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

module Start_signal(
    input logic clk,
    input logic rst,
    input logic [2:0] start_num,
    output logic start_trig
);

    logic [2:0] prev_num;

    always_ff @( posedge clk or posedge rst ) begin : COMPARE
        if(rst) prev_num <= 0;
        else begin
            if(prev_num != start_num) start_trig <= 1;
            else start_trig <= 0;
        end

        prev_num <= start_num;
    end

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
    input logic [7:0] addin,
    output logic [7:0] outvalue,
    output logic [3:0] outrepeat,
    output logic [7:0] add_num
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
                add_num <= addin + 1;
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