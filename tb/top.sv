module top;
	
	//include pkg file;
	import  test_pkg::*;
	//import uvm_pkg::*;
	import uvm_pkg::*;
	
	//include uvm_macros.svh;
	`include "uvm_macros.svh"
	
	//clk generation
	bit clk;
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	//interface instanciation
	axi_if aif(clk);
	
	//dut instanciation

	initial begin
		`ifdef VCS 
			$fsdbDumpvars(0, top);
		`endif
		uvm_config_db#(virtual axi_if)::set(null,"*","aif0",aif);
		run_test();
	end

	
	//awvalid assertion 
	 property AWVALID; 
		@(posedge clk) aif.awvalid && !aif.awready |=> $stable(aif.awvalid) && $stable(aif.awid) && $stable(aif.awlen) && $stable(aif.awsize) &&  $stable(aif.awburst) until aif.awready[->1]; 
	 endproperty 

	property WVALID; 
		@(posedge clk) aif.wvalid && !aif.wready |=> $stable(aif.wid) && $stable(aif.wdata) && $stable(aif.wvalid) && $stable(aif.wlast) until aif.wready[->1];
	endproperty 
	
	property BVALID; 
		@(posedge clk) aif.bvalid && !aif.bready |=> $stable(aif.bvalid) && $stable(aif.bid) && $stable(aif.bresp) until aif.bready[->1];
	endproperty 

	property ARVALID; 
		@(posedge clk) aif.arvalid && !aif.arready |=> $stable(aif.arvalid) && $stable(aif.arid) && $stable(aif.arlen) && $stable(aif.arsize) &&  $stable(aif.arburst) until aif.arready[->1]; 
	endproperty 

	property RVALID; 
		@(posedge clk) aif.rvalid && !aif.rready |=> $stable(aif.rvalid) && $stable(aif.rid) && $stable(aif.rdata) && $stable(aif.rlast) && $stable(aif.rresp) until aif.rready[->1]; 
	endproperty 

	awvld : cover property (AWVALID); 
	wvld : cover property (WVALID); 
	bvld : cover property (BVALID); 
	arvld : cover property (ARVALID);
	rvld : cover property (RVALID);

	//awsize 
	property AWSIZE;
		@(posedge clk) aif.awvalid |=> (aif.awsize == 0 || aif.awsize == 1 || aif.awsize == 2);  
	endproperty

	property ARSIZE;
		@(posedge clk) aif.arvalid |=> (aif.arsize == 0 || aif.arsize == 1 || aif.arsize == 2);  
	endproperty

	aws : cover property(AWSIZE); 
	ars : cover property(ARSIZE); 

	//aWBURST; 
	property AWBURST; 
		@(posedge clk) aif.awvalid |=> (aif.awburst !== 3); 
	endproperty 

	property ARBURST; 
		@(posedge clk) aif.arvalid |=> (aif.arburst !== 3); 
	endproperty 

	awburst : cover property (AWBURST); 
	arburst : cover property (ARBURST); 

	//address checking 
	property awaddr1; 
		@(posedge clk) aif.awburst == 2 && aif.awsize == 1 |=> aif.awaddr % 2 == 0; 
	endproperty 
	
	property awaddr2; 
		@(posedge clk) aif.awburst == 2 && aif.awsize == 2 |=> aif.awaddr % 4 == 0; 
	endproperty 

	property araddr1; 
		@(posedge clk) aif.arburst == 2 && aif.arsize == 1 |=> aif.araddr % 2 == 0; 
	endproperty 
	
	property araddr2; 
		@(posedge clk) aif.arburst == 2 && aif.arsize == 2 |=> aif.araddr % 4 == 0; 
	endproperty 


	AWADDR1 : cover property (awaddr1); 
	AWADDR2 : cover property (awaddr2); 
	ARADDR1 : cover property (araddr1); 
	ARADDR2 : cover property (araddr2); 

	//awlen 
	property AWLEN; 
		@(posedge clk) aif.awburst == 2 |=> aif.awlen inside {1, 3, 7, 15}; 
	endproperty 

	property ARLEN; 
		@(posedge clk) aif.arburst == 2 |=> aif.arlen inside {1, 3, 7, 15}; 
	endproperty 

	awlen : cover property (AWLEN); 
	arlen : cover property (ARLEN); 


endmodule
