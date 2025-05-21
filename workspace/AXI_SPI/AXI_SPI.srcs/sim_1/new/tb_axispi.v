`timescale 1ns / 1ps

module tb_axispi();

    // Parameters
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 4;

    // Testbench signals
    reg clk_tb;
    reg reset_tb;
    reg start_trig_tb;
    reg [7:0] data_in_tb;
    wire [7:0] data_out_tb;

    // AXI Lite slave dummy signals
    reg s_axi_aclk_tb;
    reg s_axi_aresetn_tb;
    reg [ADDR_WIDTH-1:0] s_axi_awaddr_tb;
    reg [2:0] s_axi_awprot_tb;
    reg s_axi_awvalid_tb;
    wire s_axi_awready_tb;
    reg [DATA_WIDTH-1:0] s_axi_wdata_tb;
    reg [(DATA_WIDTH/8)-1:0] s_axi_wstrb_tb;
    reg s_axi_wvalid_tb;
    wire s_axi_wready_tb;
    wire [1:0] s_axi_bresp_tb;
    wire s_axi_bvalid_tb;
    reg s_axi_bready_tb;
    reg [ADDR_WIDTH-1:0] s_axi_araddr_tb;
    reg [2:0] s_axi_arprot_tb;
    reg s_axi_arvalid_tb;
    wire s_axi_arready_tb;
    wire [DATA_WIDTH-1:0] s_axi_rdata_tb;
    wire [1:0] s_axi_rresp_tb;
    wire s_axi_rvalid_tb;
    reg s_axi_rready_tb;

    // Instantiate the DUT (Device Under Test)
    myaxispi_ip_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(DATA_WIDTH),
        .C_S00_AXI_ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        // User ports
        .clk(clk_tb),
        .reset(reset_tb),
        .start_trig(start_trig_tb),
        .data_out(data_out_tb),
        .data_in(data_in_tb),

        // AXI ports
        .s00_axi_aclk(s_axi_aclk_tb),
        .s00_axi_aresetn(s_axi_aresetn_tb),
        .s00_axi_awaddr(s_axi_awaddr_tb),
        .s00_axi_awprot(s_axi_awprot_tb),
        .s00_axi_awvalid(s_axi_awvalid_tb),
        .s00_axi_awready(s_axi_awready_tb),
        .s00_axi_wdata(s_axi_wdata_tb),
        .s00_axi_wstrb(s_axi_wstrb_tb),
        .s00_axi_wvalid(s_axi_wvalid_tb),
        .s00_axi_wready(s_axi_wready_tb),
        .s00_axi_bresp(s_axi_bresp_tb),
        .s00_axi_bvalid(s_axi_bvalid_tb),
        .s00_axi_bready(s_axi_bready_tb),
        .s00_axi_araddr(s_axi_araddr_tb),
        .s00_axi_arprot(s_axi_arprot_tb),
        .s00_axi_arvalid(s_axi_arvalid_tb),
        .s00_axi_arready(s_axi_arready_tb),
        .s00_axi_rdata(s_axi_rdata_tb),
        .s00_axi_rresp(s_axi_rresp_tb),
        .s00_axi_rvalid(s_axi_rvalid_tb),
        .s00_axi_rready(s_axi_rready_tb)
    );

    // Clock generation
    initial begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb; // 100MHz
    end

    initial begin
        s_axi_aclk_tb = 0;
        forever #5 s_axi_aclk_tb = ~s_axi_aclk_tb; // 100MHz
    end

    // Test procedure
    initial begin
        // Initialize
        reset_tb = 1;
        start_trig_tb = 0;
        data_in_tb = 8'h00;

        // AXI default values
        s_axi_aresetn_tb = 0;
        s_axi_awaddr_tb = 0;
        s_axi_awprot_tb = 0;
        s_axi_awvalid_tb = 0;
        s_axi_wdata_tb = 0;
        s_axi_wstrb_tb = 0;
        s_axi_wvalid_tb = 0;
        s_axi_bready_tb = 0;
        s_axi_araddr_tb = 0;
        s_axi_arprot_tb = 0;
        s_axi_arvalid_tb = 0;
        s_axi_rready_tb = 0;

        #20;
        reset_tb = 0;
        s_axi_aresetn_tb = 1;
        #20;

        // Send SPI data
        data_in_tb = 8'hA5;     // 예제 전송 데이터
        start_trig_tb = 1;      // SPI 통신 시작
        #10;
        start_trig_tb = 0;

        // 기다림 (SPI 동작 시간 고려)
        #200;

        // 확인
        $display("data_out_tb = %02x", data_out_tb);

        #100;
        $finish;
    end

endmodule
