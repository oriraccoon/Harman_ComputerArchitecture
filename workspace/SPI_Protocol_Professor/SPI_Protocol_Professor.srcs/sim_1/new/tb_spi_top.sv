interface spi_Intf();
    logic        clk;
    logic        reset;
    logic        cpol;
    logic        cpha;
    logic        start;
    logic  [7:0] tx_data;
    logic  [7:0] rx_data;
    logic        done;
    logic        ready;
    logic        SS;
endinterface

`include "uvm_macros.svh"
import uvm_pkg::*;

class spi_seq_item extends uvm_sequence_item;
    bit        cpol;
    bit        cpha;
    bit        start;
    rand bit  [7:0] tx_data;
    bit  [7:0] rx_data;
    bit        done;
    bit        ready;
    bit        SS;

	function new(string name = "spi_ITEM");
		super.new(name);		
	endfunction

	`uvm_object_utils_begin(spi_seq_item)
		`uvm_field_int(cpol, UVM_DEFAULT)
		`uvm_field_int(cpha, UVM_DEFAULT)
		`uvm_field_int(start, UVM_DEFAULT)
		`uvm_field_int(tx_data, UVM_DEFAULT)
		`uvm_field_int(rx_data, UVM_DEFAULT)
		`uvm_field_int(done, UVM_DEFAULT)
		`uvm_field_int(ready, UVM_DEFAULT)
		`uvm_field_int(SS, UVM_DEFAULT)
	`uvm_object_utils_end
endclass



class spi_sequence extends uvm_sequence #(spi_seq_item);
	`uvm_object_utils(spi_sequence)

	function new(string name = "SEQ");
		super.new(name);
	endfunction

	spi_seq_item spi_item;

	virtual task body();
		spi_item = spi_seq_item::type_id::create("spi_ITEM");

		for (int i = 0; i < 10; i++) begin
			start_item(spi_item);
			spi_item.randomize();
			`uvm_info("SEQ", $sformatf("spi item to driver cpol:%0d, cpha:%0d, start:%0d, tx_data:%0d, rx_data:%0d, done:%0d, ready:%0d",
										spi_item.cpol, spi_item.cpha, spi_item.start, spi_item.tx_data, spi_item.rx_data, spi_item.done, spi_item.ready), UVM_NONE);
			
			// spi_item.print(uvm_default_line_printer);

			finish_item(spi_item);
		end
	endtask

endclass



class spi_monitor extends uvm_monitor;
	`uvm_component_utils(spi_monitor)

	uvm_analysis_port #(spi_seq_item) send;

	function new(string name = "MON", uvm_component parent);
		super.new(name, parent);
		send = new("WRITE", this);		
	endfunction

	spi_seq_item spi_item;
	virtual spi_Intf a_if;

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		spi_item = spi_seq_item::type_id::create("spi_ITEM");
		if (!uvm_config_db#(virtual spi_Intf)::get(this, "", "a_if", a_if)) begin
			`uvm_fatal("MON", "spi_intf not found in uvm_config_db");
		end
	endfunction

	virtual task run_phase(uvm_phase phase);
		
		forever begin
			repeat (5) @(posedge a_if.clk);
            wait (a_if.done);
            wait (a_if.done);
            wait (a_if.done);
            wait (a_if.done);

			spi_item.cpol = a_if.cpol;
			spi_item.cpha = a_if.cpha;
			spi_item.start = a_if.start;
			spi_item.tx_data = a_if.tx_data;
			spi_item.rx_data = a_if.rx_data;
			spi_item.done = a_if.done;
			spi_item.ready = a_if.ready;
			spi_item.SS = a_if.SS;

			`uvm_info("MON", $sformatf("sampled cpol:%0d, cpha:%0d, start:%0d, tx_data:%0d, rx_data:%0d, done:%0d, ready:%0d",
										spi_item.cpol, spi_item.cpha, spi_item.start, spi_item.tx_data, spi_item.rx_data, spi_item.done, spi_item.ready), UVM_NONE);
			
			// spi_item.print(uvm_default_line_printer);
			
			send.write(spi_item);
		end
	endtask

endclass



class spi_driver extends uvm_driver #(spi_seq_item);
	`uvm_component_utils(spi_driver)

	function new(string name = "DRV", uvm_component parent);
		super.new(name, parent);
	endfunction

	spi_seq_item spi_item;
	virtual spi_Intf a_if;



	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		spi_item = spi_seq_item::type_id::create("spi_ITEM");

		if (!uvm_config_db#(virtual spi_Intf)::get(this, "", "a_if", a_if)) begin
			`uvm_fatal("DRV", "spi_intf not found in uvm_config_db");
		end
	endfunction

	virtual task run_phase(uvm_phase phase);
		a_if.reset = 1;
		#10 a_if.reset = 0;
        repeat (3) @(posedge a_if.clk);
	
		forever begin
			seq_item_port.get_next_item(spi_item);

            // write address byte
            a_if.SS = 1;
            @(posedge a_if.clk);
            a_if.tx_data = 8'b1000_0000;
            a_if.start = 1;
            a_if.cpol = 0;
            a_if.cpha = 0;
            a_if.SS = 0;
            @(posedge a_if.clk);
            a_if.start = 0;
            repeat (799) @(posedge a_if.clk);
            @(posedge a_if.clk);

            // write data byte on 0x01 address

            @(posedge a_if.clk);
            a_if.tx_data = spi_item.tx_data;
            a_if.start = 1;
            a_if.cpol = 0;
            a_if.cpha = 0;
            a_if.SS = 0;
            @(posedge a_if.clk);
            a_if.start = 0;
            repeat (799) @(posedge a_if.clk);
            @(posedge a_if.clk);

            // address byte
            a_if.SS = 1;
            @(posedge a_if.clk);
            a_if.tx_data = 8'b0000_0000;
            a_if.start = 1;
            a_if.cpol = 0;
            a_if.cpha = 0;
            a_if.SS = 0;
            @(posedge a_if.clk);
            a_if.start = 0;
            repeat (799) @(posedge a_if.clk);
            @(posedge a_if.clk);

            @(posedge a_if.clk);
            a_if.start = 1;
            @(posedge a_if.clk);
            a_if.start = 0;
            repeat (701) @(posedge a_if.clk);
            @(posedge a_if.clk);
            repeat (97) @(posedge a_if.clk);
            @(posedge a_if.clk);


			`uvm_info("DRV", $sformatf("Drive DUT cpol:%0d, cpha:%0d, start:%0d, tx_data:%0d, rx_data:%0d, done:%0d, ready:%0d",
										spi_item.cpol, spi_item.cpha, spi_item.start, spi_item.tx_data, spi_item.rx_data, spi_item.done, spi_item.ready), UVM_NONE);
			
			// spi_item.print(uvm_default_line_printer);
			
			@(posedge a_if.clk);
			a_if.tx_data = spi_item.tx_data;
			seq_item_port.item_done();
		end
	endtask //

endclass



class spi_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(spi_scoreboard)

	uvm_analysis_imp #(spi_seq_item, spi_scoreboard) recv;

	spi_seq_item spi_item;


	function new(string name = "SCB", uvm_component parent);
		super.new(name, parent);
		recv = new("READ", this);
	endfunction //new()

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		spi_item = spi_seq_item::type_id::create("spi_ITEM");
	endfunction

	virtual function void write(spi_seq_item item);
		spi_item = item;
		// spi_item.print(uvm_default_line_printer);

		if (spi_item.tx_data == spi_item.rx_data) begin
			`uvm_info("SCB", $sformatf("*** spi TEST PASSED *** tx_data:%0d, rx_data:%0d",
										spi_item.tx_data, spi_item.rx_data), UVM_LOW);
			 
		end
		else begin
			`uvm_info("SCB", $sformatf("*** spi TEST FAILED *** Received tx_data:%0d, rx_data:%0d",
										spi_item.tx_data, spi_item.rx_data), UVM_LOW);
			
		end

	endfunction

endclass //spi_scoreboard




class spi_agent extends uvm_agent;
	`uvm_component_utils(spi_agent)

	function new(string name = "AGT", uvm_component parent);
		super.new(name, parent);
	endfunction //new()

	spi_monitor spi_mon;
	spi_driver spi_drv;
	uvm_sequencer #(spi_seq_item) spi_sqr;

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		spi_sqr = uvm_sequencer#(spi_seq_item)::type_id::create("SQR", this);
		spi_drv = spi_driver::type_id::create("DRV", this);
		spi_mon = spi_monitor::type_id::create("MON", this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		spi_drv.seq_item_port.connect(spi_sqr.seq_item_export);		
	endfunction


endclass //spi_agent



class spi_envirnment extends uvm_env;
	`uvm_component_utils(spi_envirnment)

	function new(string name = "ENV", uvm_component parent);
		super.new(name, parent);
	endfunction

	spi_scoreboard spi_scb;
	spi_agent spi_agt;

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		spi_scb = spi_scoreboard::type_id::create("SCB", this);
		spi_agt = spi_agent::type_id::create("AGT", this);
	endfunction

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		spi_agt.spi_mon.send.connect(spi_scb.recv); // TLM Port 연결	/ 모니터에서 스코어보드로 던져주는 절차	
	endfunction

endclass



class test extends uvm_test;
	`uvm_component_utils(test)

	function new(string name = "TEST", uvm_component c);
		super.new(name, c);
	endfunction

	spi_sequence spi_seq;
	spi_envirnment spi_env;

	virtual function void build_phase(uvm_phase phase); // overriding
		super.build_phase(phase);
		spi_seq = spi_sequence::type_id::create("SEQ", this); // factory excute. spi_seq
		spi_env = spi_envirnment::type_id::create("ENV", this);	
	endfunction

	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this); // until drop
		spi_seq.start(spi_env.spi_agt.spi_sqr);
		phase.drop_objection(this); // objection 해제 run_phase 종료료
	endtask

endclass


module tb_spi_top();
	// test spi_test;
	spi_Intf a_if();

    spi_top dut(
        .clk(a_if.clk),
        .reset(a_if.reset),
        .cpol(a_if.cpol),
        .cpha(a_if.cpha),
        .start(a_if.start),
        .tx_data(a_if.tx_data),
        .rx_data(a_if.rx_data),
        .done(a_if.done),
        .ready(a_if.ready),
        .SS(a_if.SS)
    );

	always #5 a_if.clk = ~a_if.clk;

	initial begin
		// GUI로 보기 위함! (Verdi)
		// 그걸 위해 테스트벤치의 데이터 수집, 저장!
		$fsdbDumpvars(0);
		$fsdbDumpfile("wave.fsdb");
		a_if.clk = 0;

		// spi_test = new("TEST", null);
		uvm_config_db #(virtual spi_Intf)::set(null, "*", "a_if", a_if);

		run_test();	
	end

endmodule
