/************************************************************************
  
Copyright 2019 - Maven Silicon Softech Pvt Ltd.  
  
www.maven-silicon.com 
  
All Rights Reserved. 
This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd. 
It is not to be shared with or used by any third parties who have not enrolled for our paid 
training courses or received any written authorization from Maven Silicon.
  
Filename:       ram_test_pkg.sv
  
Author Name:    Putta Satish

Support e-mail: For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

Version:	1.0

************************************************************************/
package test_pkg;


	//import uvm_pkg.sv
	import uvm_pkg::*;
	//include uvm_macros.sv
	`include "uvm_macros.svh"
	//`include "tb_defs.sv"
	`include "transaction.sv"
	`include "master_config.sv"
	`include "slave_config.sv"
	`include "env_config.sv"
	`include "mdriver.sv"
	`include "mmonitor.sv"
	`include "msequencer.sv"
	`include "master_agt.sv"
	`include "master_uvc.sv"
	`include "msequence.sv"
	
	//`include "destination_xtn.sv"
	`include "smonitor.sv"
	`include "ssequencer.sv"
	//`include "router_destination_seqs.sv"
	`include "sdriver.sv"
	`include "slave_agt.sv"
	`include "slave_uvc.sv"
	
	//`include "router_virtual_sequencer.sv"
	//`include "router_virtual_seqs.sv"
	`include "scoreboard.sv"
	
	`include "env.sv"
	
	
	`include "test.sv"
endpackage
