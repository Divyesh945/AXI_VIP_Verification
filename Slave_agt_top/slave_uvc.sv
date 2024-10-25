class slave_uvc extends uvm_env;
	//factory registration
	`uvm_component_utils(slave_uvc)
	
	//config handle
	env_config tb_cfg;
	
	slave_agt sagt[];
	
	//methods 
	extern function new(string name="slave_uvc", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
endclass

function slave_uvc::new(string name="slave_uvc", uvm_component parent);
	super.new(name, parent);
endfunction 

function void slave_uvc::build_phase(uvm_phase phase);
	if(!uvm_config_db#(env_config)::get(this,"","env_config",tb_cfg))
		`uvm_fatal("env","env config getting failed")		

	sagt = new[tb_cfg.no_of_slave];
	foreach(sagt[i])
	begin
		sagt[i] = slave_agt::type_id::create($sformatf("sagt[%0d]",i),this);
		uvm_config_db#(slave_config)::set(this,$sformatf("sagt[%0d]*",i), "slave_config", tb_cfg.s_cfg[i]);
	end
endfunction
