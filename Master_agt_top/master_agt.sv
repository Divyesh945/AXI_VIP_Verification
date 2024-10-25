class master_agt extends uvm_agent;
	//factory registration
	`uvm_component_utils(master_agt)

	//master config handle
	master_config m_cfg;

	//handles	
	mdriver drvh;
	mmonitor monh;
	msequencer seqrh;

	//methods
	extern function new(string name="master_agt", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void connect_phase(uvm_phase phase);
endclass

function master_agt::new(string name="master_agt", uvm_component parent);
	super.new(name, parent);
endfunction 

function void master_agt::build_phase(uvm_phase phase);
	if(!uvm_config_db#(master_config)::get(this,"","master_config", m_cfg))
		`uvm_fatal("master_agt","config getting failed")
	
	monh = mmonitor::type_id::create("monh",this);
	if(m_cfg.is_active == UVM_ACTIVE)
	begin
		drvh = mdriver::type_id::create("drvh",this);
		seqrh = msequencer::type_id::create("seqrh", this);
	end

endfunction

function void master_agt::connect_phase(uvm_phase phase);
	if(m_cfg.is_active == UVM_ACTIVE)
		drvh.seq_item_port.connect(seqrh.seq_item_export);
endfunction
