module test1(
    input clk,
    input rst,
    input mod,
    output [7:0] seg,
    output [3:0] an
);

wire o_clk, fnd_clk;
wire [$clog2(9999)-1:0] num;
wire [3:0] one_num, ten_num, hund_num, thou_num;

clk_divider half_sec(
    .clk(clk),
    .rst(rst),
    .o_clk(o_clk)
);

clk_divider #(.FCOUNT(100_000)) khz (
    .clk(clk),
    .rst(rst),
    .o_clk(fnd_clk)
);

counter_num one(
    .rst(rst),
    .tick(o_clk),
    .mod(mod),
    .one_num(one_num),
    .ten_num(ten_num),
    .hund_num(hund_num),
    .thou_num(thou_num)
);

fnd_ctrl u_fnd_ctrl (
    .one_place(one_num),
    .ten_place(ten_num),
    .hund_place(hund_num),
    .thou_place(thou_num),
    .clk(fnd_clk),
    .rst(rst),
    .seg(seg),
    .an(an)
);

endmodule


module clk_divider #(
    parameter FCOUNT = 10_000_000
) (
    input clk,
    input rst,
    output reg o_clk
);

reg [$clog2(FCOUNT - 1)-1:0] counter;


always @(posedge clk or posedge rst) begin
    if(rst) begin
        o_clk <= 0;
        counter <= 0;
    end
    else begin
        if(counter == FCOUNT - 1) begin
            o_clk <= 1;
            counter <= 0;
        end else begin
            counter <= counter + 1;
            o_clk <= 0;
        end
    end
end
    
endmodule


module counter_num (
    input rst,
    input tick,      
    input mod,      
    output reg [3:0] one_num,
    output reg [3:0] ten_num,
    output reg [3:0] hund_num,
    output reg [3:0] thou_num
);

always @(posedge tick or posedge rst) begin
    if (rst) begin
        one_num <= 0;
        ten_num <= 0;
        hund_num <= 0;
        thou_num <= 0;
    end else begin
        case (mod)
            0: begin
                if (one_num == 9) begin
                    one_num <= 0;
                    if(ten_num == 9) begin
                        ten_num <= 0;
                        if(hund_num == 9) begin
                            hund_num <= 0;
                            if(thou_num == 9) begin
                                thou_num <= 0;
                            end else thou_num <= thou_num + 1;
                        end else hund_num <= hund_num + 1;
                    end else ten_num <= ten_num + 1;
                end else one_num <= one_num + 1;
            end
            1: begin
                if (one_num == 0) begin
                    one_num <= 9;
                    if(ten_num == 0) begin
                        ten_num <= 9;
                        if(hund_num == 0) begin
                            hund_num <= 9;
                            if(thou_num == 0) begin
                                thou_num <= 9;
                            end else thou_num <= thou_num - 1;
                        end else hund_num <= hund_num - 1;
                    end else ten_num <= ten_num - 1;
                end else one_num <= one_num - 1;
            end
        endcase
    end
end

endmodule

module fnd_ctrl (
    input [3:0] one_place,
    input [3:0] ten_place,
    input [3:0] hund_place,
    input [3:0] thou_place,
    input clk,
    input rst,
    output reg [7:0] seg,
    output reg [3:0] an
);

wire dp;

dp_blink U_DP(
    .clk(clk),
    .rst(rst),
    .dp(dp)
);

function [6:0] bcdseg(
    input [3:0] bcd
);
begin
        case (bcd)
            4'h0:  bcdseg = 7'h40;
            4'h1:  bcdseg = 7'h79;
            4'h2:  bcdseg = 7'h24;
            4'h3:  bcdseg = 7'h30;
            4'h4:  bcdseg = 7'h19;
            4'h5:  bcdseg = 7'h12;
            4'h6:  bcdseg = 7'h02;
            4'h7:  bcdseg = 7'h78;
            4'h8:  bcdseg = 7'h00;
            4'h9:  bcdseg = 7'h10;
            default: bcdseg = 7'h7F;
        endcase
end
endfunction


initial begin
    seg = 8'hC0;
    an = 4'b1110;
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        an <= 4'b1110;
        seg <= 8'hC0;
    end
    else begin
        case (an)
            4'b0111: begin
                an <= 4'b1110;
                seg <= {1'b1, bcdseg(one_place)};
            end
            4'b1110: begin
                an <= 4'b1101;
                seg <= {dp, bcdseg(ten_place)};
            end 
            4'b1101: begin
                an <= 4'b1011;
                seg <= {1'b1, bcdseg(hund_place)};
            end
            4'b1011: begin
                an <= 4'b0111;
                seg <= {1'b1, bcdseg(thou_place)};
            end
        endcase
    end
end

endmodule

module dp_blink(
    input clk,
    input rst,
    output reg dp
);

wire o_clk;

clk_divider #(.FCOUNT(500)) khz (
    .clk(clk),
    .rst(rst),
    .o_clk(o_clk)
);

always @(posedge o_clk or posedge rst) begin
    if(rst) begin
        dp <= 0;
    end
    else begin
        dp <= ~dp;
    end
end

endmodule
