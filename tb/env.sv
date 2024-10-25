class env extends uvm_env;
	//factory registration
	`uvm_component_utils(env)
	
	//config handles
	env_config tb_cfg;

	master_uvc magt_uvc;
 	slave_uvc sagt_uvc;
	scoreboard sb;
	//methods
	extern function new(string name="env", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
endclass

function env::new(string name="env", uvm_component parent);
	super.new(name, parent);
endfunction

function void env::build_phase(uvm_phase phase);
	if(!uvm_config_db#(env_config)::get(this,"","env_config",tb_cfg))
		`uvm_fatal("env","env config getting failed")
	
	if(tb_cfg.has_master)
	begin
		magt_uvc = master_uvc::type_id::create("magt_uvc",this);
	end

	if(tb_cfg.has_slave)
	begin
		sagt_uvc = slave_uvc::type_id::create("sagt_uvc",this);
	end
	if(tb_cfg.has_scoreboard)
	begin
		sb = scoreboard::type_id::create("sb",this);
	end
endfunction

function void env::connect_phase(uvm_phase phase);
	if(tb_cfg.has_scoreboard)
	begin
		magt_uvc.magt[0].monh.monitor_port.connect(sb.fifoh1.analysis_export);
		sagt_uvc.sagt[0].monh.monitor_port.connect(sb.fifoh2.analysis_export);
	end
endfunction
