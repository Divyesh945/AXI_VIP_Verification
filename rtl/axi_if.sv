interface axi_if(input bit clk);
	//list of signals 
	//write address channel signals
	logic [3:0] awid;
	logic [31:0] awaddr;
	logic [3:0] awlen;
	logic [2:0] awsize;
	logic [1:0] awburst;
	logic awvalid, awready;
	
	//write data channel signals
	logic [3:0] wid;
	logic [31:0] wdata;
	logic [3:0] wstrb;
	logic wvalid, wready, wlast;
	

	//write response channel signals
	logic [3:0] bid;
	logic [1:0] bresp;
	logic bvalid, bready;

	//read address channel signals
	logic [3:0] arid;
	logic [31:0] araddr;
	logic [3:0] arlen;
	logic [2:0] arsize;
	logic [1:0] arburst;
	logic arvalid, arready;
	
	//read data channel signals
	logic [3:0] rid;
	logic [31:0] rdata;
	logic [1:0] rresp;
	logic rvalid, rready, rlast;

	
	//clocking block for master driver
	clocking mdrv_cb @(posedge clk);
		default input #1 output #1;
		
		//write channels
		
		// input output signals for write addresss channel
		output awid, awaddr, awlen, awsize, awburst, awvalid;
		input awready;
	
		//input output signals for write data channel
		output wid, wdata, wstrb, wvalid, wlast;
		input wready;

		//input output signals for write response signals
		//check this out one		
		input bid, bvalid, bresp;
		output bready;

		
		//read channels

		//input output signals for read address channel
		output arid, araddr, arlen, arsize, arburst, arvalid;
		input arready;
		
		//input output singals for read data channel
		input rid, rdata, rresp, rvalid, rlast;
		output rready;		
	endclocking

	//clocking block for master monitor
	clocking mmon_cb @(posedge clk);
		default input #1 output #1;
	
		//write channels		

		//input signals for write address channel
		input awid, awaddr, awlen, awsize, awburst, awvalid, awready;

		//input signals for write data channel
		input wid, wdata, wstrb, wvalid, wlast, wready;
	
		//input signals for write response channel
		input bid, bresp, bvalid, bready;

		//read channels
		
		//input signals for read address channel
		input arid, araddr, arlen, arsize, arburst, arvalid, arready;
		
		//input signals for read data channel 
		input rid, rdata, rresp, rvalid, rlast, rready;
		
	endclocking
	

	//clocking block for slave monitor
	clocking sdrv_cb @(posedge clk);
		default input #1 output #1;

		//write channels		

		// input output signals for write addresss channel
		input awid, awaddr, awlen, awsize, awburst, awvalid;
		output awready;
	
		//input output signals for write data channel
		input wid, wdata, wstrb, wvalid, wlast;
		output wready;

		//input output signals for write response signals
		//check this out one		
		output bid, bvalid, bresp;
		input bready;

		//read channels

		//input output signals for read address channel
		input arid, araddr, arlen, arsize, arburst, arvalid;
		output arready;
		
		//input output singals for read data channel
		output rid, rdata, rresp, rvalid, rlast;
		input rready;
	endclocking
	
	//clocking block for slave monitor
	clocking smon_cb @(posedge clk);
		default input #1 output #1;
		
		//write channels
		
		//input signals for write address channel
		input awid, awaddr, awlen, awsize, awburst, awvalid, awready;

		//input signals for write data channel
		input wid, wdata, wstrb, wvalid, wlast, wready;
	
		//input signals for write response channel
		input bid, bresp, bvalid, bready;

		//read channels
		
		//input signals for read address channel
		input arid, araddr, arlen, arsize, arburst, arvalid, arready;
		
		//input signals for read data channel 
		input rid, rdata, rresp, rvalid, rlast, rready;
		
	endclocking

	modport MDRV_MP (clocking mdrv_cb);
	modport MMON_MP (clocking mmon_cb);
	modport SDRV_MP (clocking sdrv_cb);
	modport SMON_MP (clocking smon_cb);


endinterface
