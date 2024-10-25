class sdriver extends uvm_driver#(transaction);
	//factory registration 
	`uvm_component_utils(sdriver)
	
	virtual axi_if.SDRV_MP aif;

	//for write channels
	semaphore wac = new(1);
	semaphore wdc = new(1);
	semaphore wrc = new(1);
	semaphore wadc = new();
	semaphore wdrc = new();

	//for read channels
	semaphore rac = new(1);
	semaphore rdc = new(1);
	semaphore radc = new();

	//associative array
	int mem[int];


	transaction q1[$], q2[$], q3[$];

	slave_config s_cfg;

	//methods
	extern function new(string name="sdriver", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task send_to_dut();
	extern task waddc();
	extern task wdatac(transaction xtn);
	extern task wrespc(transaction xtn);
	extern task raddc();
	extern task rdatac(transaction xtn);
endclass

function sdriver::new(string name="sdriver", uvm_component parent);
	super.new(name, parent);
endfunction

function void sdriver::build_phase(uvm_phase phase);
	if(!uvm_config_db#(slave_config)::get(this,"","slave_config",s_cfg))
		`uvm_fatal(get_type_name(), "config getting failed")
	req=transaction::type_id::create("req");
endfunction 

function void sdriver::connect_phase(uvm_phase phase);
	this.aif = s_cfg.aif;
endfunction 

task sdriver::run_phase(uvm_phase phase);
	forever
		send_to_dut();
endtask

task sdriver::send_to_dut();
/*	q1.push_back(xtn);
	q2.push_back(xtn);
	q3.push_back(xtn);*/
	fork
		//write address channel		
		begin
			wac.get(1);
			waddc();
			wac.put(1);
			wadc.put(1);
		end
		//write data channel
		begin
			wdc.get(1);
			wadc.get(1);
			`uvm_info(get_type_name(),"second semaphore is unlocked",UVM_HIGH)
			wdatac(q1.pop_front());
			wdc.put(1);
			wdrc.put(1);
		end
		//write response channel
		begin
			wrc.get(1);
			wdrc.get(1);
			wrespc(q2.pop_front());
			wrc.put(1);
		end
		
		//read address channel
		begin
			rac.get(1);
			raddc();
			rac.put(1);
			radc.put(1);
		end	
		
		//read data channel
		begin
			rdc.get(1);
			radc.get(1);
			rdatac(q3.pop_front());
			rdc.put(1);
		end
	join_any
endtask

//write address channel
task sdriver::waddc();

	transaction xtn;
	xtn = transaction::type_id::create("xtn");
	aif.sdrv_cb.awready <= 0;
	repeat($urandom_range(1,5))
	begin
		@(aif.sdrv_cb);
		`uvm_info(get_type_name(),$sformatf("inside urandom_range function = %0t",$time), UVM_HIGH)
	end
	aif.sdrv_cb.awready <= 1;
	while(aif.sdrv_cb.awvalid !== 1'b1)
	begin
		@(aif.sdrv_cb);
		`uvm_info(get_type_name(),"Valid is not equals to 1", UVM_HIGH)
	end
//	aif.sdrv_cb.awready<=1;	
	xtn.awvalid = aif.sdrv_cb.awvalid;
	xtn.awid = aif.sdrv_cb.awid;
	xtn.awaddr = aif.sdrv_cb.awaddr;
	xtn.awlen = aif.sdrv_cb.awlen;
	xtn.awsize = aif.sdrv_cb.awsize;
	xtn.awburst = aif.sdrv_cb.awburst;
	xtn.awready = 1'b1;
	@(aif.sdrv_cb);	
	//while(aif.sdrv_cb.awvalid != 1'b0)
	//	@(aif.sdrv_cb);
	aif.sdrv_cb.awready<= 0;

	xtn.bid = xtn.awid;
	q1.push_back(xtn);
	q2.push_back(xtn);
	`uvm_info(get_type_name(),$sformatf("from slave driver \n%0s",xtn.sprint()), UVM_LOW)
	repeat($urandom_range(0,5))
		@(aif.sdrv_cb);
endtask

//write data channel
task sdriver::wdatac(transaction xtn);
	//@(aif.sdrv_cb); //added extra //change
	`uvm_info(get_type_name(),"inside wdatac",UVM_HIGH)
	//from here**
	xtn.waddr_calc();
	xtn.wstrobe = new[xtn.awlen+1];
	xtn.wdata= new[xtn.awlen+1];
	aif.sdrv_cb.wready <= 1'b0;//changed
	//@(aif.sdrv_cb); //changed
	 `uvm_info(get_type_name(),$sformatf("from slave driver \n%0s",xtn.sprint()), UVM_LOW)
	for(int i=0; i<(xtn.awlen+1); i++)
	begin
		@(aif.sdrv_cb); //changed
		while(aif.sdrv_cb.wvalid !== 1'b1)
		begin
			@(aif.sdrv_cb);
		end	
		
		xtn.wvalid = aif.sdrv_cb.wvalid;
		xtn.wid = aif.sdrv_cb.wid;
		xtn.wstrobe[i] = aif.sdrv_cb.wstrb;
		//$display("wstrobe[%0d] ======= %b",i, xtn.wstrobe[i]);
		if(xtn.wstrobe[i] == 4'b0001) //1
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[7:0];
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0010)//2
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[15:8];
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0011)//3
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[15:0];
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0100)//4
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[23:16];
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0110)//6
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[23:8];
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b0111)//7
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[23:0];
			mem[xtn.naddress[i]] = xtn.wdata[i];		
		end

		else if(xtn.wstrobe[i] == 4'b1000)//8
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[31:24];
			mem[xtn.naddress[i]] = xtn.wdata[i];	
		end		

		else if(xtn.wstrobe[i] == 4'b1100)//12
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[31:16];
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b1110)//14
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata[31:8];
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end

		else if(xtn.wstrobe[i] == 4'b1111)//15
		begin
			xtn.wdata[i] = aif.sdrv_cb.wdata;
			mem[xtn.naddress[i]] = xtn.wdata[i];
		end
		
		if(i == xtn.awlen)
		begin
			xtn.wlast = aif.sdrv_cb.wlast;
		end
		aif.sdrv_cb.wready <= 1'b1;
		@(aif.sdrv_cb);
		aif.sdrv_cb.wready <= 1'b0;
		//@(aif.sdrv_cb); //changed
	end
	`uvm_info(get_type_name(),$sformatf("from slave driver \n%0s",xtn.sprint()), UVM_LOW)
	`uvm_info(get_type_name(),$sformatf("from slave write data channel associative mem is \n%0p",mem),UVM_LOW)
endtask


//write response channel
task sdriver::wrespc(transaction xtn);
	@(aif.sdrv_cb);
	xtn.bvalid = 1;
	aif.sdrv_cb.bvalid<= 1'b1;
	aif.sdrv_cb.bid<=xtn.bid;
	aif.sdrv_cb.bresp<=2'b00;
	while(aif.sdrv_cb.bready !== 1'b1)
		@(aif.sdrv_cb);
	aif.sdrv_cb.bvalid<=1'b0;
	aif.sdrv_cb.bid<=4'bx;
	aif.sdrv_cb.bresp<=2'bx;
	repeat($urandom_range(0,5))
		@(aif.sdrv_cb);
	`uvm_info(get_type_name(),$sformatf("from slave driver respnose channel\n%0s",xtn.sprint()), UVM_LOW)
endtask

//read address channel
task sdriver::raddc();
transaction xtn;
	xtn = transaction::type_id::create("xtn");
	aif.sdrv_cb.arready <= 0;
	repeat($urandom_range(1,5))
	begin
		@(aif.sdrv_cb);
		`uvm_info(get_type_name(),$sformatf("inside urandom_range function = %0t",$time), UVM_HIGH)
	end
	aif.sdrv_cb.arready <= 1;
	while(aif.sdrv_cb.arvalid !== 1'b1)
	begin
		@(aif.sdrv_cb);
		`uvm_info(get_type_name(),"Valid is not equals to 1", UVM_HIGH)
	end
//	aif.sdrv_cb.awready<=1;	
	xtn.arvalid = aif.sdrv_cb.arvalid;
	xtn.arid = aif.sdrv_cb.arid;
	xtn.araddr = aif.sdrv_cb.araddr;
	xtn.arlen = aif.sdrv_cb.arlen;
	xtn.arsize = aif.sdrv_cb.arsize;
	xtn.arburst = aif.sdrv_cb.arburst;
	xtn.arready = 1'b1;
	@(aif.sdrv_cb);	
	//while(aif.sdrv_cb.awvalid != 1'b0)
	//	@(aif.sdrv_cb);
	aif.sdrv_cb.arready<= 0;

	//q1.push_back(xtn);
	q3.push_back(xtn);
	`uvm_info(get_type_name(),$sformatf("from slave driver read address channel \n%0s",xtn.sprint()), UVM_LOW)
	repeat($urandom_range(0,5))
		@(aif.sdrv_cb);	
endtask

//read data channel
task sdriver::rdatac(transaction xtn);
	aif.sdrv_cb.rvalid<=1'b0;
	@(aif.sdrv_cb);
	`uvm_info(get_type_name(),$sformatf("make it high after wards inside wdatac xtn=%0s",xtn.sprint()),UVM_HIGH)	
	xtn.raddr_calc();
	
	`uvm_info(get_type_name(),"From the driver write data channel",UVM_MEDIUM)
	//	$display("-----------------------------------------------\n\n%0d",xtn.naddress[0]);
	foreach(xtn.rnaddress[i])
	begin
		xtn.rvalid = 1'b1;
		aif.sdrv_cb.rvalid <=1'b1;
		aif.sdrv_cb.rid <= xtn.arid;
		`uvm_info(get_type_name(),$sformatf("rnaddress[%0d]=%0p",i,mem[xtn.rnaddress[i]]),UVM_LOW)
		aif.sdrv_cb.rdata <= $urandom; 
		aif.sdrv_cb.rresp <= 2'b00;
		//aif.mdrv_cb.wstrb <= xtn.wstrobe[i];
		if(i == xtn.arlen)
		begin
			aif.sdrv_cb.rlast <= 1'b1;
		end
		@(aif.sdrv_cb);
		while(aif.sdrv_cb.rready !== 1'b1)
			@(aif.sdrv_cb);
		aif.sdrv_cb.rvalid <= 1'b0;
		aif.sdrv_cb.rid<= 4'bx;
		aif.sdrv_cb.rdata<=32'bx;
		aif.sdrv_cb.rresp <= 2'bx;
		aif.sdrv_cb.rlast<=1'b0;
		repeat($urandom_range(1,3))
			@(aif.sdrv_cb);
		
	end
	`uvm_info(get_type_name(),$sformatf("from slave driver read data channel \n%0s",xtn.sprint()), UVM_LOW)
endtask
