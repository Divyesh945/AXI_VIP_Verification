class msequence extends uvm_sequence#(transaction);
	//factory registration
	`uvm_object_utils(msequence)

	function new(string name = "msequence");
		super.new(name);
	endfunction
	env_config tb_cfg;
	task body();
		if(!uvm_config_db#(env_config)::get(null,get_full_name(),"env_config",tb_cfg))
			`uvm_fatal("sequence","getting failed")
	endtask

endclass

class seq1 extends msequence;
	//factory registration
	`uvm_object_utils(seq1)

	function new(string name = "seq1");
		super.new(name);
	endfunction
	
	


	task body();
		super.body();
		`uvm_info("sequence",$sformatf("no of trans=%0d",tb_cfg.no_of_trans),UVM_LOW)
		repeat(tb_cfg.no_of_trans)
		begin
			req = transaction::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {awaddr inside {[1:25]}; awburst == 2'b00; //for write signals
					   	     araddr inside {[1:25]}; arburst == 2'b00; awsize dist {0:=1, 1:=5, 2:=4};
						});
			finish_item(req);
		end	
	endtask
endclass

class seq2 extends msequence;
	//factory registration
	`uvm_object_utils(seq2)

	function new(string name = "seq2");
		super.new(name);
	endfunction
	
	


	task body();
		super.body();
		`uvm_info("sequence",$sformatf("no of trans=%0d",tb_cfg.no_of_trans),UVM_LOW)
		repeat(tb_cfg.no_of_trans)
		begin
			req = transaction::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {awaddr inside {[1:25]}; awburst == 2'b01; awsize dist {0:=2, 1:=5, 2:=1};//for write signals
					   	     araddr inside {[1:25]}; arburst == 2'b01; arsize dist {0:=4, 1:=5, 2:=5};
						});
			finish_item(req);
		end	
	endtask
endclass

class seq3 extends msequence;
	//factory registration
	`uvm_object_utils(seq3)

	function new(string name = "seq3");
		super.new(name);
	endfunction
	
	


	task body();
		super.body();
		`uvm_info("sequence",$sformatf("no of trans=%0d",tb_cfg.no_of_trans),UVM_LOW)
		repeat(tb_cfg.no_of_trans)
		begin
			req = transaction::type_id::create("req");
			start_item(req);
			assert(req.randomize() with {awaddr inside {[1:25]}; awburst == 2'b10; //for write signals
					   	     araddr inside {[1:25]}; arburst == 2'b10; arsize dist {0:=2, 1:=1, 2:=3};
						});
			finish_item(req);
		end	
	endtask
endclass
