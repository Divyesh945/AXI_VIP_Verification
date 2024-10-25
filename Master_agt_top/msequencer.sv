class msequencer extends uvm_sequencer#(transaction);
	//factory registration
	`uvm_component_utils(msequencer)
	
	//methods
	function new(string name="msequencer",uvm_component parent);	
		super.new(name, parent);
	endfunction 
endclass
