`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/29 11:31:55
// Design Name: 
// Module Name: vga_image
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

typedef enum { BASE, GRAY, RED, GREEN, BLUE } state_e;


module Filter_mux (
    input logic clk,
    input logic reset,
    input  logic sel,
    input  logic btn,
    input  logic [11:0] x0,
    input  logic [11:0] x1,
    input  logic [11:0] x2,
    input  logic [11:0] x3,
    input  logic [11:0] x4,
    output logic [11:0] y
);

    state_e state;

    decis_state U_STATE(
        .*
    );

    always_comb begin
        case (sel)
            1'b1: begin
                case (state)
                    BASE: y = x0;
                    GRAY: y = x1;
                    RED: y = x2;
                    GREEN: y = x3;
                    BLUE: y = x4;
                    default: y = x0;
                endcase
            end
            1'b0: y = x0;
        endcase
        
    end
endmodule

module decis_state (
    input logic clk,
    input logic reset,
    input  logic sel,
    input  logic btn,
    output state_e state
);

    logic o_btn;

    state_e next;

    btn_edge_trigger U_BTN_DEBOUNCE(
        .*,
        .i_btn(btn)
    );

    // always_ff @( posedge clk or posedge reset ) begin
    //     if (reset) begin
    //         state <= BASE;
    //     end
    //     else begin
    //         state <= next;
    //     end
    // end

    always_ff @( posedge o_btn ) begin
        case (state)
            BASE: state = GRAY;
            GRAY: state = RED;
            RED: state = GREEN;
            GREEN: state = BLUE;
            BLUE: state = BASE;
            default: state = BASE;
        endcase
    end

endmodule

module Mode_demux (
    input logic [2:0] sel,
    output logic VGA_SIZE,
    output logic CROMA_KEY
);
    
    always_comb begin
        case (sel)
            3'b001: VGA_SIZE = 1;
            3'b010: CROMA_KEY = 1;
            default: begin
                VGA_SIZE = 0;
                CROMA_KEY = 0;
            end
        endcase
    end

endmodule






// debounce logic
module btn_edge_trigger(
                        input logic clk,
                        input logic rst,
                        input logic i_btn,
                        output logic o_btn
);

    logic o_clk, Edge_trigger;
    logic edge_detect;
    logic [7:0] q_reg;
    logic [7:0] q_next;
    

k_Hz_changer khc(
    .clk(clk),
    .rst(rst),
    .o_clk(o_clk)
);

Shift_Register_8 sr(
    .clk(o_clk),
    .rst(rst),
    .i_btn(i_btn),
    .q_reg(q_reg),
    .q_next(q_next)
);

AND_Gate_8input ag(
    .q_reg(q_reg),
    .Edge_trigger(Edge_trigger)
);

Edge_detecter ed(
    .clk(clk),
    .rst(rst),
    .Edge_trigger(Edge_trigger),
    .edge_detect(edge_detect)
);

    always @(posedge o_clk, posedge rst) begin
        if(rst) q_reg <= 0;
        else q_reg <= q_next;
    end

    assign o_btn = Edge_trigger & ~edge_detect;

endmodule


// 1. clock 100MHz -> 1KHz
module k_Hz_changer(
    input logic clk,
    input logic rst,
    output logic o_clk
);

	parameter FCOUNT = 100_000;

    logic [$clog2(FCOUNT)-1:0] r_counter;
    logic r_clk;

    assign o_clk = r_clk;

    always@(posedge clk, posedge rst) begin
        if(rst) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if(r_counter == FCOUNT - 1 ) begin // 1kHz
                r_counter <= 0;
                r_clk <= 1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end
endmodule

// 2. 8 Shift Register
module Shift_Register_8 (
    input logic clk,
    input logic rst,
    input logic i_btn,
    input logic [7:0] q_reg,
    output logic [7:0] q_next
);

    always @(*) begin
        // q_reg 현재의 상위 7비트를 다음의 하위 7비트에 넣고, 최상위에는 i_btn을 넣어라
        q_next = {i_btn, q_reg[7:1]};
    end
    
endmodule

// 3. 8 input AND Gate
module AND_Gate_8input (
    input logic [7:0] q_reg,
    output logic Edge_trigger
);

    assign Edge_trigger = &q_reg;
    
endmodule

// 4. Edge detecter
module Edge_detecter (
    input logic clk,
    input logic rst,
    input logic Edge_trigger,
    output logic edge_detect
);

    always @(posedge clk, posedge rst) begin
        if(rst) edge_detect <= 0;
        else edge_detect <= Edge_trigger;
    end

endmodule

