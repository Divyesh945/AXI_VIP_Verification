class base_test extends uvm_test;
	//factory registration
	`uvm_component_utils(base_test)

	//config handles
	env_config tb_cfg;
	master_config m_cfg[];
	slave_config s_cfg[];

	//env handle
	env envh;
	
	//bit variables 
	bit has_scoreboard=1;
	bit has_master=1;
	bit has_slave=1;

	//int variables
	int no_of_master = 1;
	int no_of_slave  = 1;
	int no_of_trans  = 10;
		
	//methods 
	extern function new(string name= "base_test", uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern function void config_axi();
endclass

function base_test::new(string name="base_test", uvm_component parent);
	super.new(name, parent);
endfunction 

function void base_test::build_phase(uvm_phase phase);
	tb_cfg = env_config::type_id::create("tb_cfg");
	if(has_master)
		tb_cfg.m_cfg = new[no_of_master];
	if(has_slave)
		tb_cfg.s_cfg = new[no_of_slave];

	config_axi();

	tb_cfg.no_of_trans = this.no_of_trans;
	
	uvm_config_db#(env_config)::set(this,"*","env_config",tb_cfg);
	envh = env::type_id::create("envh", this);
endfunction

function void base_test::config_axi();
	if(has_master)
	begin
		m_cfg = new[no_of_master];
		foreach(m_cfg[i])
		begin
			m_cfg[i] = master_config::type_id::create($sformatf("m_cfg[%0d]",i));
			if(!uvm_config_db#(virtual axi_if)::get(this,"",$sformatf("aif%0d",i),m_cfg[i].aif))
				`uvm_fatal("bast_test","config getting failed")
			m_cfg[i].is_active = UVM_ACTIVE;
			tb_cfg.m_cfg[i] = m_cfg[i];
		end
	end

	if(has_slave)
	begin
		s_cfg = new[no_of_slave];
		foreach(s_cfg[i])
		begin
			s_cfg[i] = slave_config::type_id::create($sformatf("s_cfg[%0d]",i));
			if(!uvm_config_db#(virtual axi_if)::get(this,"",$sformatf("aif%0d",i),s_cfg[i].aif))
				`uvm_fatal("base_test","config getting failed")
			s_cfg[i].is_active = UVM_ACTIVE;
			tb_cfg.s_cfg[i] = s_cfg[i];
		end
	end

	tb_cfg.has_scoreboard = has_scoreboard;
	tb_cfg.has_master = has_master;
	tb_cfg.has_slave = has_slave;
	tb_cfg.no_of_master = no_of_master;
	tb_cfg.no_of_slave = no_of_slave;
endfunction


class test1 extends base_test;
	//factory registration\
	`uvm_component_utils(test1)
	
	seq1 seqh;	

	function new(string name="test1", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seqh = seq1::type_id::create("seqh");
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		seqh.start(envh.magt_uvc.magt[0].seqrh);
		#15000;
		phase.drop_objection(this);
	endtask 
endclass	


class test2 extends base_test;
	//factory registration\
	`uvm_component_utils(test2)
	
	seq2 seqh;	

	function new(string name="test2", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seqh = seq2::type_id::create("seqh");
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		seqh.start(envh.magt_uvc.magt[0].seqrh);
		#15000;
		phase.drop_objection(this);
	endtask 
endclass

class test3 extends base_test;
	//factory registration\
	`uvm_component_utils(test3)
	
	seq3 seqh;	

	function new(string name="test3", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		seqh = seq3::type_id::create("seqh");
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		seqh.start(envh.magt_uvc.magt[0].seqrh);
		#15000;
		phase.drop_objection(this);
	endtask 
endclass
