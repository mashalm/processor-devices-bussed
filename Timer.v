
module Timer(clk, reset, dbus, address, wrtEn);

	parameter DBITS = 32;
	parameter CNTBASE = 32'hF000_0020;
	parameter LIMBASE = 32'hF000_0024;
	parameter CTRLBASE = 32'hF000_0120;
	parameter CLKDIV;
	
	input clk, reset, wrtEn;	
	inout[DBITS-1: 0] dbus;
	input[DBITS-1: 0] address;
	
	reg[DBITS-1: 0] tcount, tlim, tctrl, cycles;
	
	wire selCount = (address==CNTBASE);
	wire wrtCount = (wrtEn && selCount);
	wire rdCount = (!wrtEn && selCount);

	wire selLim = (address == LIMBASE);
	wire wrtLim = (wrtEn && selLim);
	wire rdLim = (!wrtEn && selLim);
			
	wire selCtrl = (address==CTRLBASE);
	wire wrtCtrl = (wrtEn && selCtrl);
	wire rdCtrl = ((!wrtEn)&&selCtrl);
	
	always @ (posedge clk) begin
		if (wrtCount) tcount <= dbus;
		else if(wrtLim) tlim <= dbus;
		else if(wrtCtrl) begin //how to set/clear ready and overrun?
			if(dbus[0]==1'b0) tctrl[0] <= 1'b0;
			if(dbus[2]==1'b0) tctrl[2] <= 1'b0;
		end
		//if we reached the countdown:
		else if(tcount >= tlim - 1) begin
			tcount <= 32'd0;
			//status bits:
			if(tctrl[0] == 1'b1) tctrl[2] <= 1;
			else tctrl[0] <= 1'b1;
		end
		else if(cycles == CLKDIV-1) begin
			cycles <= 32'd0;
			tcount <= tcount + 1;
		end
		else cycles <= cycles + 1;
	end //always
	
	assign dbus = rdCtrl ? tctrl : 
						rdCount ? tcount :
						rdLim ? tlim :
						{DBITS{1'b0}};

endmodule