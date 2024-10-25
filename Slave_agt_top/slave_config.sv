class slave_config extends uvm_object;
	//factory registration
	`uvm_object_utils(slave_config)

	//interface 
	virtual axi_if aif;
	
	uvm_active_passive_enum is_active = UVM_ACTIVE;

	//function new;
	function new(string name= "slave_config");
		super.new(name);
	endfunction

endclass


