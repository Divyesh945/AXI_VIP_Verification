class env_config extends uvm_object;
	//factory registration
	`uvm_object_utils(env_config)
	
	//config handles
	master_config m_cfg[];
	slave_config s_cfg[];
	
	//bit variables
	bit has_scoreboard = 1;
	bit has_master = 1;
	bit has_slave = 1;
	
	//int variables 
	int no_of_master =1;
	int no_of_slave = 1;
	int no_of_trans = 1;
	//function new
	function new(string name="env_config");
		super.new(name);
	endfunction
endclass
