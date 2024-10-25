class slave_agt extends uvm_agent;
	//factory registration
	`uvm_component_utils(slave_agt)

	//master config handle
	slave_config s_cfg;

	//handles	
	sdriver drvh;
	smonitor monh;
	ssequencer seqrh;

	//methods
	extern function new(string name="slave_agt", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
endclass

function slave_agt::new(string name="slave_agt", uvm_component parent);
	super.new(name, parent);
endfunction 

function void slave_agt::build_phase(uvm_phase phase);
	if(!uvm_config_db#(slave_config)::get(this,"","slave_config", s_cfg))
		`uvm_fatal("slave_agt","config getting failed")
	
	monh = smonitor::type_id::create("monh",this);
	if(s_cfg.is_active == UVM_ACTIVE)
	begin
		drvh = sdriver::type_id::create("drvh",this);
		seqrh = ssequencer::type_id::create("seqrh", this);
	end

endfunction

function void slave_agt::connect_phase(uvm_phase phase);
	if(s_cfg.is_active == UVM_ACTIVE)
		drvh.seq_item_port.connect(seqrh.seq_item_export);
endfunction
