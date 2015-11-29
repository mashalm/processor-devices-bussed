
module SwitchController(clk, reset, wrtEn, dbus, address, switches);

	parameter DBITS = 32;
	parameter SW_NAMESPACE = 32'hF000_0014;
	parameter SWCTRL_ADDR = 32'hF000_0114;
	parameter DEBOUNCE_COUNT;
	
	input clk, reset, wrtEn;
	input[DBITS-1:0] address;
	inout[DBITS-1:0] dbus;
	
	input[9:0] switches;
	
	wire rdSwitches = !wrtEn && (address==SW_NAMESPACE);
	wire rdSwCtrl = !wrtEn && (address==SWCTRL_ADDR);
	wire wrtSwCtrl = wrtEn && (address==SWCTRL_ADDR);
	
	reg[9:0] prevSwData, swData;
	reg[DBITS-1:0] holdCount;
	reg holdSw, overrun, ready;
	
	always @(posedge clk) begin
		if(reset==1'b1) begin
			prevSwData <= 10'd0;
			overrun <= 1'b0;
			ready <= 1'b0;
			holdSw <= 1'b0;
		end
		else begin
			if(rdSwitches==1'b1) begin
				ready <= 1'b0;
				overrun <= 1'b0;
			end
			else if(wrtSwCtrl) begin
				if(dbus[2]==1'b0) overrun <= dbus[2];
			end
			if(!holdSw && (prevSwData != switches)) begin
				prevSwData <= switches;
				holdCount <= 32'd0;
				holdSw <= 1'b1;
			end
			if(holdSw) begin
				holdCount <= holdCount + 1'b1;
				if(prevSwData != switches) holdSw <= 1'b0;
				if(holdCount == DEBOUNCE_COUNT) begin
					swData <= prevSwData;
					if(ready==1'b1) overrun <= 1'b1;
					else ready <=1'b1;
					holdCount <= 32'd0;
					holdSw <=1'b0;
				end
			end
		end
		
	end//always
	
	assign dbus = rdSwitches ? {22'd0, swData} :
						rdSwCtrl ? {29'd0,overrun,1'b0,ready} :
						{DBITS{1'bz}};
	
endmodule