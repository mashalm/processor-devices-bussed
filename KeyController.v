
module KeyController(clk, reset, dbus, address, wrtEn, keys);

	parameter DBITS = 32;
	parameter MY_NAMESPACE = 32'hF000_0010;
	parameter KCTRL_ADDR = 32'hF000_0110;

	input clk, wrtEn, reset;
	inout[DBITS-1:0] dbus;
	input[DBITS-1:0] address;
	input[3:0] keys;
	
	wire selKdata = (address == MY_NAMESPACE);
	wire rdKdata = selKdata && !wrtEn;
	//no writing to keys
	
	wire rdKCtrl = (address == KCTRL_ADDR) && !wrtEn;
	wire wrtKCtrl = (address == KCTRL_ADDR) && wrtEn;
	
	//keycont has two regs: one handling its data,
	//and the other holding some control info <- aren't doing
	reg ready, overrun;
	reg[3:0] kdata, prevKdata;
	
	always @ (posedge clk) begin
		if(reset == 1'b1) begin
			ready <= 1'b0;
			overrun <= 1'b0;
			prevKdata <= 4'h0;
		end 
		else begin
			if(rdKdata) begin
				ready <= 1'b0;
				overrun <= 1'b0;
			end
			else if(wrtKCtrl) begin
				if(dbus[2]==1'b0) overrun <= dbus[2];
			end
			if(keys != prevKdata) begin
				prevKdata <= keys;
				if(ready==1'b1) overrun<=1'b1;
				else ready <=1'b1;
			end
		end		
	end //always
	
	assign dbus = rdKdata ? {28'd0, prevKdata} :
						rdKCtrl ? {29'd0, overrun,1'b0,ready} :
						{DBITS{1'bz}};

endmodule