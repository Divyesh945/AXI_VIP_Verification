class smonitor extends uvm_monitor;
	//factory registration 
	`uvm_component_utils(smonitor)
	
	virtual axi_if.SMON_MP aif;
	

	slave_config s_cfg;
	
	uvm_analysis_port#(transaction) monitor_port;
	
	//semaphores
	//writing side
	semaphore wac=new(1);
	semaphore wdc=new(1);
	semaphore wrc=new(1);
	semaphore wadc = new();
	semaphore wdrc = new();
	
	//reading side
	semaphore rac=new(1);
	semaphore rdc=new(1);
	semaphore radc=new();


	transaction q1[$], q2[$], q3[$];

	//methods
	extern function new(string name="smonitor", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task collect_data();
	extern task waddc();
	extern task wdatac(transaction xtn);
	extern task wrespc(transaction xtn);
	extern task raddc();
	extern task rdatac(transaction xtn);
endclass

function smonitor::new(string name="smonitor", uvm_component parent);
	super.new(name, parent);
endfunction

function void smonitor::build_phase(uvm_phase phase);
	if(!uvm_config_db#(slave_config)::get(this,"","slave_config",s_cfg))
		`uvm_fatal(get_type_name(), "config getting failed")

	monitor_port = new("monitor_port", this);
endfunction 

function void smonitor::connect_phase(uvm_phase phase);
	this.aif = s_cfg.aif;
endfunction 

task smonitor::run_phase(uvm_phase phase);
	forever 
		collect_data();
endtask

task smonitor::collect_data();
	fork
		begin
			wac.get(1);
			waddc();
			wac.put(1);
			wadc.put(1);
		end
	
		begin
			wdc.get(1);
			wadc.get(1);
			wdatac(q1.pop_front());
			wdc.put(1);
			wdrc.put(1);
		end

		begin
			wrc.get(1);
			wdrc.get(1);
			wrespc(q2.pop_front());
			wrc.put(1);
		end
		
		begin
			rac.get(1);
			raddc();
			rac.put(1);
			radc.put(1);
		end

		begin
			rdc.get(1);
			radc.get(1);
			rdatac(q3.pop_front());
			rdc.put(1);
		end
	join_any
endtask

task smonitor::waddc();
	transaction xtn;
	xtn = transaction::type_id::create("xtn");
		@(aif.smon_cb);
	
	while(aif.smon_cb.awvalid !== 1'b1 || aif.smon_cb.awready !== 1'b1)
	begin
		@(aif.smon_cb);
		`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
	end
	
	xtn.awvalid = aif.smon_cb.awvalid;
	xtn.awid = aif.smon_cb.awid;
	xtn.awaddr = aif.smon_cb.awaddr;
	xtn.awlen = aif.smon_cb.awlen;
	xtn.awsize = aif.smon_cb.awsize;
	xtn.awburst = aif.smon_cb.awburst;
	//`uvm_info(get_type_name(),$sformatf("from mater monitor \n%0s",xtn.sprint()), UVM_LOW)
	q1.push_back(xtn);
endtask

task smonitor::wdatac(transaction xtn);
	
		
	xtn.waddr_calc();
	xtn.wstrobe = new[xtn.awlen+1];
	xtn.wdata= new[xtn.awlen+1];
	// `uvm_info(get_type_name(),$sformatf("from master monitor \n%0s",xtn.sprint()), UVM_MEDIUM)
	for(int i=0; i<(xtn.awlen+1); i++)
	begin
		@(aif.smon_cb);
		while(aif.smon_cb.wvalid !== 1'b1 || aif.smon_cb.wready !== 1'b1)
		begin
			@(aif.smon_cb);
			`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
		end		
		xtn.wvalid = aif.smon_cb.wvalid;
		xtn.wid = aif.smon_cb.wid;
		xtn.wstrobe[i] = aif.smon_cb.wstrb;
		//$display("wstrobe[%0d] ======= %b",i, xtn.wstrobe[i]);
		if(xtn.wstrobe[i] == 4'b0001) //1
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[7:0];
		end
	
		else if(xtn.wstrobe[i] == 4'b0010)//2
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[15:8];
		end
	
		else if(xtn.wstrobe[i] == 4'b0011)//3
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[15:0];
		end
	
		else if(xtn.wstrobe[i] == 4'b0100)//4
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[23:16];
		end
	
		else if(xtn.wstrobe[i] == 4'b0110)//6
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[23:8];
		end
	
		else if(xtn.wstrobe[i] == 4'b0111)//7
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[23:0];		
		end
	
		else if(xtn.wstrobe[i] == 4'b1000)//8
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[31:24];
		end		
	
		else if(xtn.wstrobe[i] == 4'b1100)//12
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[31:16];
		end
		
		else if(xtn.wstrobe[i] == 4'b1110)//14
		begin
			xtn.wdata[i] = aif.smon_cb.wdata[31:8];
		end
	
		else if(xtn.wstrobe[i] == 4'b1111)//15
		begin
			xtn.wdata[i] = aif.smon_cb.wdata;
		end
			
		if(i == xtn.awlen)
		begin
			xtn.wlast = aif.smon_cb.wlast;
		end
	end
	//`uvm_info(get_type_name(),$sformatf("from mater monitor \n%0s",xtn.sprint()), UVM_LOW)
	q2.push_back(xtn);
endtask


task smonitor::wrespc(transaction xtn);
	@(aif.smon_cb);
	while(aif.smon_cb.bvalid !== 1'b1 || aif.smon_cb.bready !== 1'b1)
	begin
		@(aif.smon_cb);
		`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
	end
	xtn.bid = aif.smon_cb.bid;
	xtn.bresp = aif.smon_cb.bresp;	
	//`uvm_info(get_type_name(),$sformatf("from master monitor \n%0s",xtn.sprint()), UVM_LOW)
	monitor_port.write(xtn);
endtask

task smonitor::raddc();
	transaction xtn;
	xtn = transaction::type_id::create("xtn");
	@(aif.smon_cb);
	while(aif.smon_cb.arvalid !== 1'b1 || aif.smon_cb.arready !== 1'b1)
	begin
		@(aif.smon_cb);
		`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
	end
	
	xtn.arvalid = aif.smon_cb.arvalid;
	xtn.arid = aif.smon_cb.arid;
	xtn.araddr = aif.smon_cb.araddr;
	xtn.arlen = aif.smon_cb.arlen;
	xtn.arsize = aif.smon_cb.arsize;
	xtn.arburst = aif.smon_cb.arburst;
	xtn.arready = 1'b1;
	q3.push_back(xtn);
endtask

task smonitor::rdatac(transaction xtn);

	xtn.raddr_calc();
	xtn.strobe_calc(); 
	//xtn.wstrobe = new[xtn.awlen+1];
	xtn.rdata= new[xtn.arlen+1];
	for(int i=0; i<(xtn.arlen+1); i++)
	begin
		@(aif.smon_cb);
		while(aif.smon_cb.rvalid !== 1'b1 || aif.smon_cb.rready !== 1'b1)
		begin
			@(aif.smon_cb);	
			`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
		end
		xtn.rvalid = aif.smon_cb.rvalid;
		xtn.rid = aif.smon_cb.rid;
		if(xtn.wstrobe[i] == 4'b0001) //1
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[7:0];
		end

		else if(xtn.wstrobe[i] == 4'b0010)//2
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[15:8];
		end

		else if(xtn.wstrobe[i] == 4'b0011)//3
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[15:0];
		end

		else if(xtn.wstrobe[i] == 4'b0100)//4
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[23:16];
		end

		else if(xtn.wstrobe[i] == 4'b0110)//6
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[23:8];
		end

		else if(xtn.wstrobe[i] == 4'b0111)//7
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[23:0];
		end

		else if(xtn.wstrobe[i] == 4'b1000)//8
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[31:24];
		end		

		else if(xtn.wstrobe[i] == 4'b1100)//12
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[31:16];
		end

		else if(xtn.wstrobe[i] == 4'b1110)//14
		begin
			xtn.rdata[i] = aif.smon_cb.wdata[31:8];
		end

		else if(xtn.wstrobe[i] == 4'b1111)//15
		begin
			xtn.rdata[i] = aif.smon_cb.wdata;
		end

		
		xtn.rresp = aif.smon_cb.rresp;
		if(i == xtn.arlen)
		begin
			xtn.rlast = aif.smon_cb.rlast;
		end
	end
	//`uvm_info(get_type_name(),$sformatf("from master monitor \n%0s",xtn.sprint()), UVM_LOW)
	monitor_port.write(xtn);
endtask

