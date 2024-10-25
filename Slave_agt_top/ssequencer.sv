class ssequencer extends uvm_sequencer#(transaction);
	//factory registration
	`uvm_component_utils(ssequencer)
	
	//methods
	function new(string name="ssequencer",uvm_component parent);	
		super.new(name, parent);
	endfunction 
endclass
