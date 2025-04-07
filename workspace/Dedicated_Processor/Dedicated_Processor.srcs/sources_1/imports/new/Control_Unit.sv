module Control_Unit(
    input logic clk,
    input logic rst,
    input logic altb,
    input logic start_trig,

    output logic asel,
    output logic aen,
    output logic outbuf
    );

    // parameter IDLE = 0, INITIALIZE = 1, COMPARE = 2, OUTVAL = 3, ADD = 4, HELT = 5;
    typedef enum { IDLE = 0, INITIALIZE = 1, COMPARE = 2, OUTVAL = 3, ADD = 4, HELT = 5 } state_e;
    state_e state, next;

    always_ff @(posedge clk or posedge rst) begin : Initialize
        if (rst) begin
            state <= IDLE;
        end
        else begin
            state <= next;
        end
    end

    always_comb begin : CU_FSM
        next = state;
        case (state)
            IDLE: begin
                asel = 0;
                aen = 0;
                outbuf = 0;
                next = INITIALIZE;
            end
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
                if(altb) next = OUTVAL;
                else next = HELT;
            end
            OUTVAL: begin
                asel = 0;
                aen = 0;
                outbuf = 0;
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
                outbuf = 1;
                if (start_trig) next = IDLE;
            end
            default: begin
                asel = 0;
                aen = 0;
                outbuf = 0;
            end
        endcase
    end


endmodule
