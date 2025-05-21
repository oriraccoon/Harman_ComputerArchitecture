`timescale 1ns / 1ps

module I2C_Master (
    // General signals
    input            clk,
    input            reset,
    // I2C ports
    inout            SCL,
    inout            SDA,
    // external signals
    input      [7:0] tx_data,
    output     [7:0] rx_data,
    input [6:0] addr,
    input wren,
    input            start,
    output           tx_done,
    output           ready
);

    localparam
        IDLE = 0,
        START = 1,
        ADDR_READ = 2,
        READ_ACK = 3,
        WRITE_DATA = 4,
        READ_DATA = 5,
        READ_ACK2 = 6,
        STOP = 7
    ;

    reg [2:0] state;
    reg [1:0] count;
    reg [$clog2(250)-1:0] clk_count;
    reg i2c_clk;
    reg scl_reg, sda_reg;
    reg [7:0] temp_tx_data;
    reg [6:0] temp_addr_data;
    reg temp_wren;
    reg [2:0] bit_count;
    reg write_en;

    assign SDA = (write_en) ? sda_reg : 1'bz;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i2c_clk <= 0;
        end
        else begin
            if (clk_count == 249) begin
                i2c_clk <= ~i2c_clk;
                clk_count = 0;
            end
            else begin
                clk_count = clk_count + 1;
            end
        end
    end

    always @(posedge i2c_clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            scl_reg <= 1;
            sda_reg <= 1;
            count <= 0;
            bit_count <= 0;
            temp_tx_data <= 0;
            write_en <= 1;
            temp_addr_data <= 0;
            temp_wren <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        sda_reg <= 0;
                        state <= START;
                    end
                end  
                START: begin
                    sda_reg <= 0;
                    scl_reg <= 0;
                    if (count == 3) begin
                        state <= ADDR_READ;
                        temp_addr_data <= addr;
                        temp_wren <= wren;
                        count = 0;
                        bit_count = 0;
                    end
                    else count = count + 1;
                end
                ADDR_READ: begin
                    if (count == 1) begin
                        scl_reg <= 1;
                    end
                    else if (count == 3) begin
                        scl_reg <= 0;
                        if (bit_count == 7) begin
                            state <= READ_ACK;
                            bit_count = 0;
                        end
                        else begin
                            temp_addr_data <= {temp_addr_data[5:0], 1'b0};
                            bit_count <= bit_count + 1;
                        end
                    end

                    count <= count + 1;

                    if (bit_count != 7) begin
                        sda_reg <= temp_addr_data[6];
                    end
                    else begin
                        sda_reg <= temp_wren;
                    end
                    
                end
                READ_ACK: begin
                    write_en <= 0;
                    count <= count + 1;
                    if (count == 2) begin
                        if (!SDA) begin
                            state <= (temp_wren) ? READ_DATA : WRITE_DATA;
                        end
                    end
                end
                WRITE_DATA: begin
                    write_en <= 1;
                    if (count == 1) begin
                        scl_reg <= 1;
                    end
                    else if (count == 3) begin
                        scl_reg <= 0;
                        if (bit_count == 7) begin
                            state <= READ_ACK2;
                            bit_count = 0;
                        end
                        else begin
                            temp_tx_data <= {temp_tx_data[6:0], 1'b0};
                            bit_count <= bit_count + 1;
                        end
                    end
                    count <= count + 1;
                    sda_reg <= temp_tx_data[7];
                end
                READ_DATA: begin
                    write_en <= 0;
                    
                end
                READ_ACK2: begin
                    write_en <= 0;
                    count <= count + 1;
                    if (count == 2) begin
                        if (!SDA) begin
                            state <= (temp_wren) ? READ_DATA : WRITE_DATA;
                        end
                    end
                    temp_tx_data <= tx_data;
                end
                STOP: begin
                    
                end
            endcase
        end
    end

    

endmodule