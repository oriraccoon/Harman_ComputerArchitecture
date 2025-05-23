`timescale 1ns / 1ps

module I2C_Slave_LED (
    input clk,
    input reset,
    //signal - Master
    input SCL,
    inout SDA,
    //LED
    output reg [7:0] led
);

    //sda 읽기


    localparam LED_Slave_ADDR = 7'b0000010;  // 이 slave 주소는 2임
    localparam IDLE = 0, ADDR_SAVE = 1, ADDR_MATCH = 2, DATA = 3;  //FSM 상태관리
    reg [2:0] state, state_next;
    reg [7:0] shift_reg, shift_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg sda_out_en_reg, sda_out_en_next;
    reg addr_match_reg, addr_match_next;



    assign SDA = sda_out_en_reg ? 1'b0 : 1'bz;  //sda_out_en = 1일때만 sda를 0으로 내림, 그외에는 주도권 포기

    always @(negedge SCL) begin
        if (reset) begin
            state <= IDLE;
            shift_reg <= 0;
            bit_count_reg <= 0;
            sda_out_en_reg <= 0;
            addr_match_reg <= 0;
            led <= 0;
        end else begin
            state <= state_next;
            shift_reg <= shift_next;
            bit_count_reg <= bit_count_next;
            sda_out_en_reg <= sda_out_en_next;
            addr_match_reg <= addr_match_next;
        end

        if (state == DATA && bit_count_reg == 7) begin
            led <= {shift_reg[6:0], SDA};
        end

    end


    always @(*) begin
        state_next = state;
        shift_next = shift_reg;
        bit_count_next = bit_count_reg;
        sda_out_en_next = sda_out_en_reg;
        addr_match_next = addr_match_reg;
        case (state)
            IDLE: begin
                sda_out_en_next = 1'b0;  // sda(ALK) 주도권x
                shift_next = 0;
                bit_count_next = 0;
                addr_match_next = 0;
                state_next = ADDR_SAVE;
            end
            ADDR_SAVE: begin
                sda_out_en_next = 1'b0;  // sda(ALK) 주도권x
                if (bit_count_reg < 7) begin  //7비트 주소 받음
                    shift_next = {shift_reg[6:0], SDA};
                    bit_count_next = bit_count_reg + 1;
                end else begin
                    shift_next = {shift_reg[6:0], SDA};  // R/W결정
                    sda_out_en_next = 1'b1;  //NACK
                    state_next = ADDR_MATCH;
                end
            end
            ADDR_MATCH: begin
                sda_out_en_next = 1'b0;  // sda(ALK) 주도권x
                if ((shift_reg[7:1] == LED_Slave_ADDR) && (shift_reg[0] == 1'b0)) begin  //주소가 같고, 쓰기모드이면
                    addr_match_next = 1'b1;
                    sda_out_en_next = 1'b0;  //ACK
                    bit_count_next = 0;
                    state_next = DATA;
                end else begin
                    addr_match_next = 1'b0;
                    sda_out_en_next = 1'b1;  //NACK
                    bit_count_next = 0;
                    state_next = IDLE;
                end
            end
            DATA: begin
                sda_out_en_next = 1'b0;  // sda(ALK) 주도권x
                if (addr_match_reg) begin
                    if (bit_count_reg < 8) begin  //8비트 데이터 수신
                        shift_next = {shift_reg[6:0], SDA};
                        bit_count_next = bit_count_reg + 1;
                    end else begin  //끝나면
                        sda_out_en_next = 1'b1;
                        addr_match_next  = 0;
                        bit_count_next  = 0;
                        shift_next = 0;
                        state_next = IDLE;
                    end
                end
            end
        endcase
    end

endmodule
