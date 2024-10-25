class scoreboard extends uvm_scoreboard;
	//factory registration
	`uvm_component_utils(scoreboard)

	transaction mxtn, sxtn;
	
	static int mismatched, matched;

	//tlm fifo
	uvm_tlm_analysis_fifo #(transaction) fifoh1;
	uvm_tlm_analysis_fifo #(transaction) fifoh2;

	//covergroups 
	covergroup m_cov;
		option.per_instance=1;
		//WLEN : coverpoint m_xtn.AWLEN{bins len[]={0,1,2};}
		WSIZE : coverpoint mxtn.awsize{bins siz[]={0,1,2};}
		WBURST : coverpoint mxtn.awburst{bins burst[]={0,1,2};
			illegal_bins ILLB={3};
			}
		W_SxB : cross WSIZE,WBURST;

		//RLEN : coverpoint m_xtn.ARLEN{bins len[]={0,1,2};}
		RSIZE : coverpoint mxtn.arsize{bins siz[]={0,1,2};}
		RBURST : coverpoint mxtn.arburst{bins burst[]={0,1,2};
				illegal_bins ILLB={3};
			}
		R_SxB: cross RSIZE,RBURST;
	endgroup

	covergroup s_cov;
		option.per_instance=1;
		WSIZE : coverpoint sxtn.awsize{bins siz[]={0,1,2};}
		WBURST : coverpoint sxtn.awburst{bins burst[]={0,1,2};
				illegal_bins ILLB={3};
			}
		W_LxSxB : cross WSIZE,WBURST;

		RSIZE : coverpoint sxtn.arsize{bins siz[]={0,1,2};}
		RBURST : coverpoint sxtn.arburst{bins burst[]={0,1,2};
				illegal_bins ILLB={3};
			}
		R_SxB: cross RSIZE,RBURST;
	endgroup

	//methods
	extern function new(string name = "scoreboard", uvm_component parent);	
	extern task run_phase(uvm_phase phase);
	extern task collect();
	extern function void report_phase(uvm_phase phase);
endclass

function scoreboard::new(string name="scoreboard", uvm_component parent);
	super.new(name, parent);
	fifoh1 = new("fifoh1", this);
	fifoh2 = new("fifoh2", this);
	m_cov = new();
	s_cov = new();
endfunction

task scoreboard::run_phase(uvm_phase phase);
	forever
	begin
		fifoh1.get(mxtn);
		`uvm_info(get_type_name(),$sformatf("mxtn =%0s",mxtn.sprint()),UVM_LOW)
		fifoh2.get(sxtn);
		`uvm_info(get_type_name(),$sformatf("sxtn = %0s", sxtn.sprint()),UVM_LOW)
		collect();
		m_cov.sample();
		s_cov.sample(); 
	end
endtask

task scoreboard::collect();
	if(!mxtn.compare(sxtn))
	begin
		mismatched++;
		`uvm_error(get_type_name(), "mismatched error")
	end
	else 
	begin
		matched++;
		`uvm_info(get_type_name(), "data matched",UVM_LOW)
	end
endtask

function void scoreboard::report_phase(uvm_phase phase);
	`uvm_info(get_type_name(),$sformatf("\n\n-------------------------------------------------------\nno of matched data are %0d\nno of mismatched data are %0d \n\n-------------------------------------------------------\n",matched, mismatched),UVM_NONE)
endfunction
