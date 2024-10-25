class mmonitor extends uvm_monitor;
	//factory registration
	`uvm_component_utils(mmonitor)
	
	virtual axi_if.MMON_MP aif;
	
	uvm_analysis_port#(transaction) monitor_port;
	
	master_config m_cfg;

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
	extern function new(string name="mmonitor", uvm_component parent);
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

function mmonitor::new(string name="mmonitor", uvm_component parent);
	super.new(name, parent);
endfunction

function void mmonitor::build_phase(uvm_phase phase);
	if(!uvm_config_db#(master_config)::get(this,"","master_config",m_cfg))
		`uvm_fatal(get_type_name(), "config getting failed")
		
	monitor_port = new("monitor_port",this);
endfunction 

function void mmonitor::connect_phase(uvm_phase phase);
	this.aif = m_cfg.aif;
endfunction

task mmonitor::run_phase(uvm_phase phase);
	forever 
		collect_data();
endtask

task mmonitor::collect_data();
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

task mmonitor::waddc();
	transaction xtn;
	xtn = transaction::type_id::create("xtn");
		@(aif.mmon_cb);
	
	while(aif.mmon_cb.awvalid !== 1'b1 || aif.mmon_cb.awready !== 1'b1)
	begin
		@(aif.mmon_cb);
		`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
	end
	
	xtn.awvalid = aif.mmon_cb.awvalid;
	xtn.awid = aif.mmon_cb.awid;
	xtn.awaddr = aif.mmon_cb.awaddr;
	xtn.awlen = aif.mmon_cb.awlen;
	xtn.awsize = aif.mmon_cb.awsize;
	xtn.awburst = aif.mmon_cb.awburst;
	//`uvm_info(get_type_name(),$sformatf("from mater monitor \n%0s",xtn.sprint()), UVM_LOW)
	q1.push_back(xtn);
endtask

task mmonitor::wdatac(transaction xtn);
	
		
	xtn.waddr_calc();
	xtn.wstrobe = new[xtn.awlen+1];
	xtn.wdata= new[xtn.awlen+1];
	// `uvm_info(get_type_name(),$sformatf("from master monitor \n%0s",xtn.sprint()), UVM_MEDIUM)
	for(int i=0; i<(xtn.awlen+1); i++)
	begin
		@(aif.mmon_cb);
		while(aif.mmon_cb.wvalid !== 1'b1 || aif.mmon_cb.wready !== 1'b1)
		begin
			@(aif.mmon_cb);
			`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
		end		
		xtn.wvalid = aif.mmon_cb.wvalid;
		xtn.wid = aif.mmon_cb.wid;
		xtn.wstrobe[i] = aif.mmon_cb.wstrb;
		//$display("wstrobe[%0d] ======= %b",i, xtn.wstrobe[i]);
		if(xtn.wstrobe[i] == 4'b0001) //1
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[7:0];
		end
	
		else if(xtn.wstrobe[i] == 4'b0010)//2
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[15:8];
		end
	
		else if(xtn.wstrobe[i] == 4'b0011)//3
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[15:0];
		end
	
		else if(xtn.wstrobe[i] == 4'b0100)//4
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[23:16];
		end
	
		else if(xtn.wstrobe[i] == 4'b0110)//6
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[23:8];
		end
	
		else if(xtn.wstrobe[i] == 4'b0111)//7
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[23:0];		
		end
	
		else if(xtn.wstrobe[i] == 4'b1000)//8
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[31:24];
		end		
	
		else if(xtn.wstrobe[i] == 4'b1100)//12
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[31:16];
		end
		
		else if(xtn.wstrobe[i] == 4'b1110)//14
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata[31:8];
		end
	
		else if(xtn.wstrobe[i] == 4'b1111)//15
		begin
			xtn.wdata[i] = aif.mmon_cb.wdata;
		end
			
		if(i == xtn.awlen)
		begin
			xtn.wlast = aif.mmon_cb.wlast;
		end
	end
	//`uvm_info(get_type_name(),$sformatf("from mater monitor \n%0s",xtn.sprint()), UVM_LOW)
	q2.push_back(xtn);
endtask


task mmonitor::wrespc(transaction xtn);
	@(aif.mmon_cb);
	while(aif.mmon_cb.bvalid !== 1'b1 || aif.mmon_cb.bready !== 1'b1)
	begin
		@(aif.mmon_cb);
		`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
	end
	xtn.bid = aif.mmon_cb.bid;
	xtn.bresp = aif.mmon_cb.bresp;	
	//`uvm_info(get_type_name(),$sformatf("from master monitor \n%0s",xtn.sprint()), UVM_LOW)
	monitor_port.write(xtn);
endtask

task mmonitor::raddc();
	transaction xtn;
	xtn = transaction::type_id::create("xtn");
	@(aif.mmon_cb);
	while(aif.mmon_cb.arvalid !== 1'b1 || aif.mmon_cb.arready !== 1'b1)
	begin
		@(aif.mmon_cb);
		`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
	end
	
	xtn.arvalid = aif.mmon_cb.arvalid;
	xtn.arid = aif.mmon_cb.arid;
	xtn.araddr = aif.mmon_cb.araddr;
	xtn.arlen = aif.mmon_cb.arlen;
	xtn.arsize = aif.mmon_cb.arsize;
	xtn.arburst = aif.mmon_cb.arburst;
	xtn.arready = 1'b1;
	q3.push_back(xtn);
endtask

task mmonitor::rdatac(transaction xtn);

	xtn.raddr_calc();
	xtn.strobe_calc(); 
	//xtn.wstrobe = new[xtn.awlen+1];
	xtn.rdata= new[xtn.arlen+1];
	for(int i=0; i<(xtn.arlen+1); i++)
	begin
		@(aif.mmon_cb);
		while(aif.mmon_cb.rvalid !== 1'b1 || aif.mmon_cb.rready !== 1'b1)
		begin
			@(aif.mmon_cb);	
			`uvm_info(get_type_name(),"inside waddc valid",UVM_MEDIUM)
		end
		xtn.rvalid = aif.mmon_cb.rvalid;
		xtn.rid = aif.mmon_cb.rid;
		if(xtn.wstrobe[i] == 4'b0001) //1
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[7:0];
		end

		else if(xtn.wstrobe[i] == 4'b0010)//2
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[15:8];
		end

		else if(xtn.wstrobe[i] == 4'b0011)//3
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[15:0];
		end

		else if(xtn.wstrobe[i] == 4'b0100)//4
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[23:16];
		end

		else if(xtn.wstrobe[i] == 4'b0110)//6
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[23:8];
		end

		else if(xtn.wstrobe[i] == 4'b0111)//7
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[23:0];
		end

		else if(xtn.wstrobe[i] == 4'b1000)//8
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[31:24];
		end		

		else if(xtn.wstrobe[i] == 4'b1100)//12
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[31:16];
		end

		else if(xtn.wstrobe[i] == 4'b1110)//14
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata[31:8];
		end

		else if(xtn.wstrobe[i] == 4'b1111)//15
		begin
			xtn.rdata[i] = aif.mmon_cb.wdata;
		end

		
		xtn.rresp = aif.mmon_cb.rresp;
		if(i == xtn.arlen)
		begin
			xtn.rlast = aif.mmon_cb.rlast;
		end
	end
	//`uvm_info(get_type_name(),$sformatf("from master monitor \n%0s",xtn.sprint()), UVM_LOW)
	monitor_port.write(xtn);
endtask


