class mdriver extends uvm_driver#(transaction);
	//factory registration 
	`uvm_component_utils(mdriver)
	
	virtual axi_if.MDRV_MP aif;

	master_config m_cfg;

	//associative array for master read
	int mmem[int];

	//semaphore for write channels
	semaphore wac = new(1);
	semaphore wdc = new(1);
	semaphore wrc = new(1);
	semaphore wadc = new();
	semaphore wdrc = new();

	//semaphore for read channels	
	semaphore rac = new(1);
	semaphore rdc = new(1);
	semaphore radc = new();

	transaction q1[$], q2[$], q3[$], q4[$], q5[$];

	//methods
	extern function new(string name="mdriver", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task send_to_dut(transaction xtn);
	extern task waddc(transaction xtn);
	extern task wdatac(transaction xtn);
	extern task wrspc(transaction xtn);
	extern task raddc(transaction xtn);
	extern task rdatac(transaction xtn);
endclass

function mdriver::new(string name="mdriver", uvm_component parent);
	super.new(name, parent);
endfunction

function void mdriver::build_phase(uvm_phase phase);
	if(!uvm_config_db#(master_config)::get(this,"","master_config",m_cfg))
		`uvm_fatal(get_type_name(), "config getting failed")
endfunction 

function void mdriver::connect_phase(uvm_phase phase);
	this.aif = m_cfg.aif;
endfunction 
	
task mdriver::run_phase(uvm_phase phase);
	/*req = transaction::type_id::create("req");
	assert(req.randomize() with {awaddr inside {[1:20]}; awburst == 2'b1; awlen == 5; awsize == 1; //for write signals
					   araddr inside {[1:20]}; arburst == 2'b1; arlen == 5; arsize == 1;
						});
	req.print();*/
	forever begin
		seq_item_port.get_next_item(req);
		// `uvm_info(get_type_name(),$sformatf("after get next item req = %0s",req.sprint()), UVM_LOW)
		send_to_dut(req);
		seq_item_port.item_done();
	end
endtask

task mdriver::send_to_dut(transaction xtn);
	q1.push_back(xtn);
	q2.push_back(xtn);
	q3.push_back(xtn);
	q4.push_back(xtn);
	q5.push_back(xtn);	
	fork      
		//for write address
		begin
			wac.get(1);
			waddc(q1.pop_front());
			wac.put(1);
			wadc.put(1);
		end

		//for write data
		begin
			wdc.get(1);
			wadc.get(1);
			wdatac(q2.pop_front());
			wdc.put(1);
			wdrc.put(1);
		end

		//for write response
		begin
			wrc.get(1);
			wdrc.get(1);
			wrspc(q3.pop_front());
			wrc.put(1);
		end
		
		//for read address 
		begin
			rac.get(1);
			raddc(q4.pop_front());
			rac.put(1);
			radc.put(1);
		end

		//for read data 
		begin
			rdc.get(1);
			radc.get(1);
			rdatac(q5.pop_front());
			rdc.put(1);
		end
	join_any
endtask

//for write address channel
task mdriver::waddc(transaction xtn);
	@(aif.mdrv_cb);
	xtn.awvalid = 1'b1;
	aif.mdrv_cb.awvalid <= 1'b1;
	aif.mdrv_cb.awid <= xtn.awid;
	aif.mdrv_cb.awaddr <= xtn.awaddr;
	aif.mdrv_cb.awlen <= xtn.awlen;
	aif.mdrv_cb.awsize <= xtn.awsize;
	aif.mdrv_cb.awburst <= xtn.awburst;
	@(aif.mdrv_cb);
	`uvm_info(get_type_name(), "after 1 clocking block", UVM_HIGH)
	while(aif.mdrv_cb.awready !== 1'b1)
		@(aif.mdrv_cb);
	aif.mdrv_cb.awvalid <= 1'b0;
	aif.mdrv_cb.awid <= 4'bx;
	aif.mdrv_cb.awaddr <= 32'bx;
	aif.mdrv_cb.awlen <= 4'bx;
	aif.mdrv_cb.awsize <= 3'bx;
	aif.mdrv_cb.awburst <= 2'bx;
	
	repeat($urandom_range(0,5))
		@(aif.mdrv_cb);

	`uvm_info(get_type_name(),$sformatf("from master driver \n%0s",xtn.sprint()), UVM_LOW)
endtask

//for write data channel
task mdriver::wdatac(transaction xtn);
	aif.mdrv_cb.wvalid<=1'b0;
	@(aif.mdrv_cb);
	`uvm_info(get_type_name(),$sformatf("inside wdatac xtn=%0s",xtn.sprint()),UVM_HIGH)	
	xtn.waddr_calc();
	`uvm_info(get_type_name(),"From the driver write data channel",UVM_MEDIUM)
	xtn.strobe_calc();
//	$display("-----------------------------------------------\n\n%0d",xtn.naddress[0]);
	foreach(xtn.wdata[i])
	begin
		xtn.wvalid = 1'b1;
		aif.mdrv_cb.wvalid <=1'b1;
		aif.mdrv_cb.wid <= xtn.wid;
		aif.mdrv_cb.wdata <= xtn.wdata[i];
		aif.mdrv_cb.wstrb <= xtn.wstrobe[i];
		if(i == xtn.awlen)
		begin
			aif.mdrv_cb.wlast <= 1'b1;
		end
		@(aif.mdrv_cb);
		while(aif.mdrv_cb.wready !== 1'b1)
			@(aif.mdrv_cb);
		aif.mdrv_cb.wvalid <= 1'b0;
		aif.mdrv_cb.wid<= 4'bx;
		aif.mdrv_cb.wdata<=32'bx;
		aif.mdrv_cb.wstrb<=4'bx;
		aif.mdrv_cb.wlast<=1'b0;
		repeat($urandom_range(1,3))
			@(aif.mdrv_cb);
		
	end
	`uvm_info(get_type_name(),$sformatf("from master driver data channel \n%0s",xtn.sprint()), UVM_LOW)
endtask

//for write response channel
task mdriver::wrspc(transaction xtn);
	aif.mdrv_cb.bready <= 0;
	@(aif.mdrv_cb);
	while(aif.mdrv_cb.bvalid !== 1'b1)
		@(aif.mdrv_cb);
	xtn.bid = aif.mdrv_cb.bid;
	xtn.bresp = aif.mdrv_cb.bresp;
	aif.mdrv_cb.bready<=1;	
	@(aif.mdrv_cb);
	aif.mdrv_cb.bready<=0;
	`uvm_info(get_type_name(),$sformatf("from master driver response channel \n%0s",xtn.sprint()), UVM_LOW)
endtask


//for read address channel
task mdriver::raddc(transaction xtn);
	@(aif.mdrv_cb);
	xtn.arvalid = 1'b1;
	aif.mdrv_cb.arvalid <= 1'b1;
	aif.mdrv_cb.arid <= xtn.arid;
	aif.mdrv_cb.araddr <= xtn.araddr;
	aif.mdrv_cb.arlen <= xtn.arlen;
	aif.mdrv_cb.arsize <= xtn.arsize;
	aif.mdrv_cb.arburst <= xtn.arburst;
	@(aif.mdrv_cb);
	`uvm_info(get_type_name(), "after 1 clocking block", UVM_HIGH)
	while(aif.mdrv_cb.arready !== 1'b1)
		@(aif.mdrv_cb);
	aif.mdrv_cb.arvalid <= 1'b0;
	aif.mdrv_cb.arid <= 4'bx;
	aif.mdrv_cb.araddr <= 32'bx;
	aif.mdrv_cb.arlen <= 4'bx;
	aif.mdrv_cb.arsize <= 3'bx;
	aif.mdrv_cb.arburst <= 2'bx;
	
	repeat($urandom_range(0,5))
		@(aif.mdrv_cb);

	`uvm_info(get_type_name(),$sformatf("from master driver read address\n%0s",xtn.sprint()), UVM_LOW)
endtask   
task mdriver::rdatac(transaction xtn);
	//@(aif.sdrv_cb); //added extra //change
	`uvm_info(get_type_name(),"inside rdatac",UVM_HIGH)
	//from here**
	xtn.raddr_calc();
	xtn.strobe_calc(); 
	//xtn.wstrobe = new[xtn.awlen+1];
	xtn.rdata= new[xtn.arlen+1];
	aif.mdrv_cb.rready <= 1'b0;//changed
	//@(aif.sdrv_cb); //changed
	 `uvm_info(get_type_name(),$sformatf("from master driver data channel \n%0s",xtn.sprint()), UVM_LOW)
	for(int i=0; i<(xtn.arlen+1); i++)
	begin
		@(aif.mdrv_cb); //changed
		while(aif.mdrv_cb.rvalid !== 1'b1)
		begin
			@(aif.mdrv_cb);
		end	
		
		xtn.rvalid = aif.mdrv_cb.rvalid;
		xtn.rid = aif.mdrv_cb.rid;
		if(xtn.wstrobe[i] == 4'b0001) //1
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[7:0];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0010)//2
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[15:8];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0011)//3
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[15:0];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0100)//4
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[23:16];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0110)//6
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[23:8];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0111)//7
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[23:0];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];		
		end

		else if(xtn.wstrobe[i] == 4'b1000)//8
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[31:24];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];	
		end		

		else if(xtn.wstrobe[i] == 4'b1100)//12
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[31:16];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b1110)//14
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata[31:8];
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b1111)//15
		begin
			xtn.rdata[i] = aif.mdrv_cb.rdata;
			mmem[xtn.rnaddress[i]] = xtn.rdata[i];
		end

		
		xtn.rresp = aif.mdrv_cb.rresp;
		if(i == xtn.arlen)
		begin
			xtn.rlast = aif.mdrv_cb.rlast;
		end
		aif.mdrv_cb.rready <= 1'b1;
		@(aif.mdrv_cb);
		aif.mdrv_cb.rready <= 1'b0;
		//@(aif.sdrv_cb); //changed
	end
	`uvm_info(get_type_name(),$sformatf("from master driver read data channel\n%0s",xtn.sprint()), UVM_LOW)

endtask
