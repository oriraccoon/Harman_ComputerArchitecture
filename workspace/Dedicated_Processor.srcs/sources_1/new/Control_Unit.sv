module Control_Unit(
    input logic clk,
    input logic rst,
    input logic altb,

    output logic asel,
    output logic aen,
    output logic outbuf
    );

    parameter INITIALIZE = 0, COMPARE = 1, OUTVAL = 2, ADD = 3, HELT = 4;

    logic [2:0] state, next;

    always_ff @(posedge clk or posedge rst) begin : Initialize
        if (rst) begin
            state <= 0;
        end
        else begin
            state <= next;
        end
    end

    always_comb begin : CU_FSM
        next = state;
        case (state)
            INITIALIZE: begin
                asel = 0;
                aen = 1;
                outbuf = 0;
                next = COMPARE;
            end
            COMPARE: begin
                asel = 0;
                aen = 0;
                outbuf = 0;
                if(altb) next = COMPARE;
                else next = HELT;
            end
            OUTVAL: begin
                asel = 0;
                aen = 0;
                outbuf = 1;
                next = ADD;
            end
            ADD: begin
                asel = 1;
                aen = 1;
                outbuf = 0;
                next = COMPARE;
            end
            HELT: begin
                asel = 0;
                aen = 0;
                outbuf = 0;
            end
        endcase
    end


endmodule
