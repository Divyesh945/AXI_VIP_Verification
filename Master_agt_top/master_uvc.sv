class master_uvc extends uvm_env;
	//factory registration
	`uvm_component_utils(master_uvc)
	
	//config handle
	env_config tb_cfg;

	//master_agt handle
	master_agt magt[];
	
	//methods
	extern function new(string name = "master_uvc", uvm_component parent);
	extern function void build_phase (uvm_phase phase);
	extern function void start_of_simulation_phase(uvm_phase phase);
endclass

function master_uvc::new(string name="master_uvc", uvm_component parent);
	super.new(name, parent);
endfunction

function void master_uvc::build_phase(uvm_phase phase);
	if(!uvm_config_db#(env_config)::get(this,"","env_config",tb_cfg))
		`uvm_fatal("env","env config getting failed")
	
	magt = new[tb_cfg.no_of_master];
	foreach(magt[i])
	begin
		magt[i] = master_agt::type_id::create($sformatf("magt[%0d]",i),this);
		uvm_config_db#(master_config)::set(this,$sformatf("magt[%0d]*",i), "master_config", tb_cfg.m_cfg[i]);
	end
endfunction

function void master_uvc::start_of_simulation_phase(uvm_phase phase);
	uvm_top.print_topology();
endfunction
