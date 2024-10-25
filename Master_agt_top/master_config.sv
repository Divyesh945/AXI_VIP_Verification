class master_config extends uvm_object;
	//factory registration
	`uvm_object_utils(master_config)

	//interface 
	virtual axi_if aif;

	uvm_active_passive_enum is_active = UVM_ACTIVE;
	
	//function new
	function new(string name="master_config");
		super.new(name);
	endfunction

endclass
	
