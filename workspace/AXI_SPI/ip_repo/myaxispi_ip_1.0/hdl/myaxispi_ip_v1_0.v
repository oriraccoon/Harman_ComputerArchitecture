
`timescale 1 ns / 1 ps

	module myaxispi_ip_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here
		input wire start_trig,
		output wire [7:0] data_out,
		input wire [7:0] data_in,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

	// AXI_reg
	wire [2:0] cr;
	wire [7:0] od;
	wire [7:0] id;
	wire sr;

// Instantiation of Axi Bus Interface S00_AXI
	myaxispi_ip_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myaxispi_ip_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		.cr(cr),
		.od(od),
		.id(id),
		.sr(sr)
	);
	
	// SPI_reg
	wire done;
	wire so_done;
	wire SCLK, MOSI, MISO;

	assign MISO = MOSI;

	assign data_out = od;
	// assign id = data_in;

    SPI_Master U_SPI_MASTER (
		//internal signals
		.done(done),
		.so_done(so_done),
		//external port
		.SCLK(SCLK),
		.MOSI(MOSI),
		.MISO(MISO),
		.SS(~start_trig),
        .clk(s00_axi_aclk),
        .reset(s00_axi_aresetn),
        .cpol(cr[2]),
        .cpha(cr[1]),
        .start(cr[0]),
        .tx_data(data_in),
        .rx_data(od),
        .ready(sr)
    );

    // SPI_SLAVE U_SPI_SLAVE (
	// 	.SCLK(SCLK),
	// 	.MOSI(MOSI),
	// 	.MISO(MISO),
	// 	.SS(~start_trig),
	// 	.so_done(so_done),
    //     .clk(s00_axi_aclk),
    //     .reset(s00_axi_aresetn)
    // );
	// User logic ends

	endmodule
