`timescale 1ns / 1ps

module I2C_Slave (
    // I2C ports
    inout SCL,
    inout SDA,
    output [7:0] led
);

    wire [6:0] temp_addr_data;
    wire temp_wren;
    wire [7:0] so_data;
    wire [7:0] si_data;

    assign led = so_data;

    I2C_SLAVE_REG U_I2C_REG (
        .addr(temp_addr_data),
        .wren(temp_wren),
        .so_data(so_data),
        .si_data(si_data)
    );

    I2C_Slave_Intf U_I2C_SLAVE (
        .SCL(SCL),
        .SDA(SDA),
        .temp_addr_data(temp_addr_data),
        .temp_wren(temp_wren),
        .so_data(so_data),
        .si_data(si_data)
    );

endmodule

module I2C_Slave_Intf (
    // I2C ports
    inout            SCL,
    inout            SDA,
    // external signals
    output reg [6:0] temp_addr_data,
    output reg       temp_wren,
    input      [7:0] so_data,
    output reg [7:0] si_data
);

    localparam
        IDLE = 0,
        ADDR_READ = 2,
        READ_ACK = 3,
        WRITE_DATA = 4,
        READ_DATA = 5,
        HOLD = 6,
        WRITE_ACK = 8,
        LOW = 9
    ;


    reg [3:0] state = IDLE;
    reg [3:0] bit_count = 0;
    reg write_en = 0;
    reg scl_en = 0;
    reg sda_reg = 0;
    reg scl_reg = 0;
    reg start = 0;
    reg [7:0] temp_rdata = 8'b0;
    reg [7:0] temp_wdata = 8'b0;
    reg [7:0] temp_aw = 8'b0;
    reg temp_ack = 0;
    reg count = 0;


    assign SDA = (write_en && ~sda_reg) ? 1'b0 : 1'bz;
    assign SCL = (scl_en && ~scl_reg) ? 1'b0 : 1'bz;

    always @(negedge SDA) begin
        if (SCL) begin
            start <= 1;
        end
        if (state == HOLD) begin
            temp_addr_data <= temp_addr_data + count;
            if (temp_wren) begin
                state <= WRITE_DATA;
                write_en <= 1;
                sda_reg <= temp_wdata[7];
                temp_wdata <= {temp_wdata[6:0], 1'b0};
            end
            else begin
                state <= READ_DATA;
                si_data <= 8'bx;
            end
        end
    end

    always @(posedge SDA) begin
        if (SCL) begin
            start <= 0;
            state <= IDLE;
        end
    end

    always @(posedge SCL) begin
        case (state)
            ADDR_READ: begin
                temp_aw   <= {temp_aw[6:0], SDA};
                bit_count <= bit_count + 1;
            end
            WRITE_ACK: begin
                sda_reg <= 0;
                temp_wdata <= so_data;
            end
            READ_ACK: begin
                temp_ack   <= SDA;
                temp_wdata <= so_data;
            end
            WRITE_DATA: begin
                write_en <= 1;
                if (bit_count == 8) begin
                    bit_count <= 0;
                    state <= READ_ACK;
                    write_en <= 0;
                    count <= 1;
                end
            end
            READ_DATA: begin
                temp_rdata <= {temp_rdata[6:0], SDA};
                bit_count  <= bit_count + 1;
            end
        endcase
    end

    always @(negedge SCL) begin
        if (start) begin
            case (state)
                IDLE: begin
                    scl_en <= 0;
                    bit_count <= 0;
                    temp_aw <= 0;
                    count <= 0;
                    state <= ADDR_READ;
                end
                ADDR_READ: begin
                    if (bit_count == 8) begin
                        bit_count <= 0;
                        state <= WRITE_ACK;
                        {temp_addr_data, temp_wren} <= temp_aw;
                    end
                end
                WRITE_ACK: begin
                    state <= HOLD;
                end
                READ_ACK: begin
                    state <= (temp_ack) ? IDLE : HOLD;
                end
                WRITE_DATA: begin
                    sda_reg <= temp_wdata[7];
                    temp_wdata <= {temp_wdata[6:0], 1'b0};
                    bit_count <= bit_count + 1;
                end
                READ_DATA: begin
                    if (bit_count == 8) begin
                        bit_count <= 0;
                        state <= WRITE_ACK;
                        si_data <= temp_rdata;
                        count <= 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            WRITE_ACK: write_en = 1;
            default:   write_en = 0;
        endcase
    end

endmodule


module I2C_SLAVE_REG (
    input      [6:0] addr,
    input            wren,
    input      [7:0] si_data,
    output     [7:0] so_data
);

    reg [7:0] mem[0:6];

    reg [7:0] so_data_reg;
    assign so_data = so_data_reg;
    
    always @(*) begin
        if (!wren) begin
            mem[addr] = si_data;
        end else begin
            so_data_reg = mem[addr];
        end
    end

endmodule
