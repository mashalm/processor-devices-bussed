
module HexController(clk, reset, dbus, address, wrtEn, HEX0, HEX1, HEX2, HEX3);

	parameter DBITS = 32;
	parameter MY_NAMESPACE = 32'hF000_0000;
	
	input clk, reset, wrtEn;
	inout[DBITS-1:0] dbus;
	input[DBITS-1:0] address;
	output wire[6:0] HEX0, HEX1, HEX2, HEX3;
	
	reg[15:0] hex;
	
	wire wrtHex = (address == MY_NAMESPACE) && wrtEn;
	wire rdHex = (address == MY_NAMESPACE) && !wrtEn;

	// Create SevenSeg for HEX3
	SevenSeg sevenSeg3 (
		.dIn(hex[15:12]),
		.dOut(HEX3)
	);

	// Create SevenSeg for HEX2
	SevenSeg sevenSeg2 (
		.dIn(hex[11:8]),
		.dOut(HEX2)
	);

	// Create SevenSeg for HEX1
	SevenSeg sevenSeg1 (
		.dIn(hex[7:4]),
		.dOut(HEX1)
	);

	// Create SevenSeg for HEX0
	SevenSeg sevenSeg0 (
		.dIn(hex[3:0]),
		.dOut(HEX0)
	);
	
	always @ (posedge clk) begin
		if(reset==1'b1) hex <= 16'h0000;
		else if(wrtHex) hex <= dbus[15:0];
		else hex <= 16'hDEAD;
	end
	
	//read from hexes
	assign dbus = rdHex ? {16'h0000, hex} : {DBITS{1'bz}};

endmodule