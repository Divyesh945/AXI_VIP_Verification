class transaction extends uvm_sequence_item;
	//factory registration
	`uvm_object_utils(transaction)
	
	//properties

	//write address channel signals
	rand bit [3:0] awid;
	rand bit [31:0] awaddr;
	rand bit [3:0] awlen;
	rand bit [2:0] awsize;
	rand bit [1:0] awburst;
	bit awvalid, awready;
	
	//write data channel signals
	rand bit [3:0] wid;
	rand bit [31:0] wdata[];
	rand bit [3:0] wstrobe[];
	bit wvalid, wready, wlast;
	

	//write response channel signals
	rand bit [3:0] bid;
	rand bit [1:0] bresp;
	bit bvalid, bready;

	//read address channel signals
	rand bit [3:0] arid;
	rand bit [31:0] araddr;
	rand bit [3:0] arlen;
	rand bit [2:0] arsize;
	rand bit [1:0] arburst;
	rand bit arvalid, arready;
	
	//read data channel signals
	rand bit [3:0] rid;
	rand bit [31:0] rdata[];
	rand bit [1:0] rresp;
	bit rvalid, rready, rlast;


	//extra signals for write addresss calculation
	int start_address, number_bytes, burst_length, aligned_address, naddress[], wrap_boundary;

	//extra signals for read addresss calculation
	int rstart_address, rnumber_bytes, rburst_length, raligned_address, rnaddress[], rwrap_boundary;

		

	//constraints 
	
	//for write channels
	constraint aw_burst_c{ awburst dist {0:=1, 1:=2, 2:=9}; }
	constraint aw_size_c{ awsize dist {0:=1, 1:=1, 2:=1}; }
	constraint aw_burst_c1{ (awburst == 2'b10 && awsize == 2'b01)-> awaddr%2==0;
				}
	constraint aw_burst_c2{ if(awburst == 2'b10 && awsize == 2'b10)
					awaddr % 4==0;
				}
	constraint aw_burst_c3{if(awburst == 2'b10) awlen inside {1,3,7, 15};}
	constraint wid_c { awid == wid;}
	constraint bid_c { wid == bid;}
	
	constraint wdata_c { wdata.size == awlen+1;}
	constraint wstrobe_c {wstrobe.size == wdata.size;}

	//for read channels
	constraint ar_burst_c{ arburst dist {0:=3, 1:=2, 2:=1}; }
	constraint ar_size_c{ arsize dist {0:=1, 1:=1, 2:=1}; }
	constraint ar_burst_c1{ if(arburst == 2'b10 && arsize == 2'b01)
				araddr%2==0;
				}
	constraint ar_burst_c2{ if(arburst == 2'b10 && arsize == 2'b10)
				araddr%4==0;
				}
	constraint rid_c { arid == rid;}
	
	constraint rdata_c { wdata.size == arlen+1;}
		

	function bit do_compare(uvm_object rhs, uvm_comparer comparer);
		transaction rhs_;
		if(!$cast(rhs_,rhs))
			`uvm_fatal("comparer","casting failed")

		foreach(rhs_.wdata[i])
		begin
			if(!(rhs_.wdata[i] == this.wdata[i] && rhs_.wstrobe[i] == this.wstrobe[i]))
				return 0;	
		end
		foreach(rhs_.rdata[i])
		begin
			if(!rhs_.rdata[i] == this.rdata[i])
				return 0;
		end
		return  rhs_.awaddr == this.awaddr &&
			rhs_.awlen == this.awlen &&
			rhs_.awsize == this.awsize &&
			rhs_.awburst == this.awburst &&
			rhs_.araddr == this.araddr &&
			rhs_.arlen == this.arlen &&
			rhs_.arsize == this.arsize &&
			rhs_.arburst == this.arburst;
	endfunction

	//do print methods overriding
	function void do_print(uvm_printer printer);
		//for write address channel
//		$display("signals for write address channel");
		printer.print_field("awid", this.awid, 4, UVM_DEC);
		printer.print_field("awaddr", this.awaddr, 32, UVM_DEC);
		printer.print_field("awlen", this.awlen, 4, UVM_DEC);
		printer.print_field("awsize", this.awsize, 3, UVM_DEC);
		printer.print_field("awburst", this.awburst, 2, UVM_DEC);
		printer.print_field("awvalid", this.awvalid, 1, UVM_DEC);
		printer.print_field("awready", this.awready, 1, UVM_DEC);
		
		//for write data channel
//		$display("signals for write data channel");
		printer.print_field("wid", this.wid, 4, UVM_DEC);
		foreach(wdata[i])
		printer.print_field($sformatf("wdata[%0d]",i), this.wdata[i], 32, UVM_DEC);
		foreach(wstrobe[i])
			printer.print_field($sformatf("wstrobe[%0d]",i), this.wstrobe[i], 4, UVM_BIN);
		printer.print_field("wvalid", this.wvalid, 4, UVM_DEC);
		printer.print_field("wready", this.wready, 4, UVM_DEC);
		printer.print_field("wlast", this.wlast, 4, UVM_DEC);
		
		//for write response channel
//		$display("signals for write response channel");	
		printer.print_field("bid", this.bid, 4, UVM_DEC);
		printer.print_field("bresp", this.bresp, 2, UVM_DEC);
		printer.print_field("bvalid", this.bvalid, 1, UVM_DEC);
		printer.print_field("bready", this.bready, 1, UVM_DEC);
			
		//for read address channel
//		$display("signals for read address channel");
		printer.print_field("arid", this.arid, 4, UVM_DEC);
		printer.print_field("araddr", this.araddr, 32, UVM_DEC);
		printer.print_field("arlen", this.arlen, 4, UVM_DEC);
		printer.print_field("arsize", this.arsize, 3, UVM_DEC);
		printer.print_field("arburst", this.arburst, 2, UVM_DEC);
		printer.print_field("arvalid", this.arvalid, 1, UVM_DEC);
		printer.print_field("arready", this.arready, 1, UVM_DEC);
	
		//for read data channel
//		$display("signals for read data channel"); 
		printer.print_field("rid", this.rid, 4, UVM_DEC);
		foreach(rdata[i])
			printer.print_field($sformatf("rdata[%0d]",i), this.rdata[i], 32, UVM_DEC);
		printer.print_field("rresp", this.rresp, 2, UVM_DEC);
		printer.print_field("rvalid", this.rvalid, 1, UVM_DEC);
		printer.print_field("rready", this.rready, 1, UVM_DEC);
		printer.print_field("rlast", this.rlast, 1, UVM_DEC);
	endfunction

function void waddr_calc();
		start_address = awaddr;
		number_bytes = 2 ** awsize;
		burst_length = awlen + 1;
		aligned_address = (int'(start_address/number_bytes)) * number_bytes;
		if(awburst !== 2'b00)
		begin
			if(awburst == 2'b01)
			begin
				naddress = new[awlen+1];
				foreach(naddress[i])
				begin
					if(i==0)
					begin
						naddress[i] = start_address;
					end
					else
						naddress[i] = aligned_address + (i) * number_bytes;
				end
			end
			else if(awburst == 2'b10)
			begin
				int b;
				wrap_boundary= (int'(start_address/(number_bytes * burst_length))) * (number_bytes * burst_length);
				naddress = new[awlen+1];
				foreach(naddress[i])
				begin
					if(i==0)
					begin
						naddress[i] = start_address;
					end
					
					else 
					begin
						if(b==0)
						begin
							naddress[i] = aligned_address + (i) * number_bytes;
							if(naddress[i] == (wrap_boundary + (number_bytes * burst_length)))
							begin
								naddress[i] = wrap_boundary;
								b++;
							end
						end
						else 
							naddress[i] = start_address + ((i) * number_bytes) - (number_bytes * burst_length);
					end
				end
			end
			
		end
		else
		begin
			naddress = new[awlen+1];
			foreach(naddress[i])
			begin
				naddress[i] = start_address; 
			end
		end
	
		/*`uvm_info(get_type_name(),"from write address calculation",UVM_LOW)
		$display("the Start_address = %0d", start_address);
		$display("number_bytes = %0d", number_bytes);
		$display("burst_length= %0d", burst_length);
		$display("aligned_address=%0d", aligned_address);
		$display("awburst=%0d",awburst);
		$display("awsize=%0d",awsize);
		foreach(naddress[i])
			$display("naddress[%0d]=%0d",i, naddress[i]);
		if(awburst == 2'b10)
			$display("wrap_boundary= %0d", wrap_boundary);	*/
	endfunction

	function void raddr_calc();
		rstart_address = araddr;
		rnumber_bytes = 2 ** arsize;
		rburst_length = arlen + 1;
		raligned_address = (int'(rstart_address/rnumber_bytes)) * rnumber_bytes;
		if(arburst !== 2'b00)
		begin
			if(arburst == 2'b01)
			begin
				rnaddress = new[arlen+1];
				foreach(rnaddress[i])
				begin
					if(i==0)
					begin
						rnaddress[i] = rstart_address;
					end
					else
						rnaddress[i] = raligned_address + (i) * rnumber_bytes;
				end
			end
			else if(arburst == 2'b10)
			begin
				int b;
				rwrap_boundary= (int'(rstart_address/(rnumber_bytes * rburst_length))) * (rnumber_bytes * rburst_length);
				rnaddress = new[arlen+1];
				foreach(rnaddress[i])
				begin
					if(i==0)
					begin
						rnaddress[i] = rstart_address;
					end
					
					else 
					begin
						if(b==0)
						begin
							rnaddress[i] = raligned_address + (i) * rnumber_bytes;
							if(rnaddress[i] == (rwrap_boundary + (rnumber_bytes * rburst_length)))
							begin
								rnaddress[i] = rwrap_boundary;
								b++;
							end
						end
						else 
						rnaddress[i] = rstart_address + ((i) * rnumber_bytes) - (rnumber_bytes * rburst_length);
					end
				end
			end
			
		end
		else
		begin
			rnaddress = new[arlen+1];
			foreach(rnaddress[i])
			begin
				rnaddress[i] = rstart_address; 
			end
		end
/*
		`uvm_info(get_type_name(),"from read address calculation",UVM_LOW)
		$display("the read Start_address = %0d", rstart_address);
		$display("read number_bytes = %0d", rnumber_bytes);
		$display("read burst_length= %0d", rburst_length);
		$display("read aligned_address=%0d", raligned_address);
		$display("read arburst=%0d",arburst);
		$display("read arsize=%0d",arsize);
		foreach(rnaddress[i])
			$display("read naddress[%0d]=%0d",i, rnaddress[i]);
		if(arburst == 2'b10)
			$display("read wrap_boundary= %0d", rwrap_boundary);	
*/
	endfunction
		
	

	function void strobe_calc();
		int data_bus_byte=4; //becuase we only have 4 data byte in our data	
		int lower_byte_lane;
		int upper_byte_lane;

		int lower_byte_lane_0;
		int upper_byte_lane_0;
		
		int i;
		int j;

		wstrobe = new[awlen+1];
	
		lower_byte_lane_0 = (start_address - (int'(start_address/data_bus_byte))*data_bus_byte);
		upper_byte_lane_0 = (aligned_address + (number_bytes-1) - (int'(start_address/data_bus_byte)) * data_bus_byte);

		for(j=lower_byte_lane_0; j<=upper_byte_lane_0; j++)
			wstrobe[0][j] = 1;
		
		for(i=1; i<burst_length; i++)
		begin
			lower_byte_lane= (naddress[i] - (int'(naddress[i]/data_bus_byte))* data_bus_byte);
			upper_byte_lane = lower_byte_lane + number_bytes - 1;

			for(j=lower_byte_lane; j<=upper_byte_lane; j++)
			begin
				wstrobe[i][j] = 1;
			end
		end
		
/*		foreach(wstrobe[i])
			$display("wstrobe[%0d] = %b", i ,wstrobe[i]);*/
	endfunction


	function void post_randomize();
		// waddr_calc();
		// strobe_calc();
		// raddr_calc();
	endfunction 
	
endclass	
