
module LEDController(clk, reset, dbus, address, wrtEn, led);

	parameter DBITS;
	parameter LBITS;
	parameter LED_NAMESPACE;
	
	input clk, wrtEn, reset;
	inout[DBITS-1:0] dbus;
	input[DBITS-1:0] address;
	
	wire wrtLed = wrtEn &&(address==LED_NAMESPACE);	
	wire rdLed = !wrtEn &&(address==LED_NAMESPACE);	
	
	reg[LBITS-1:0] ledData;
	
	output wire[LBITS-1:0] led = ledData;
	
	always @(posedge clk) begin
		if(reset)
			ledData <= {LBITS{1'b0}};
		else if(wrtLed) ledData <= dbus[LBITS-1:0];
	end
	
	//reading from leds:
	assign dbus = rdLed ? {22'b0,ledData} : {DBITS{1'bz}};
	
endmodule