module DataMemory(clk, wrtEn, addr, dbus);
	parameter MEM_INIT_FILE;
	parameter ADDR_BIT_WIDTH = 32;
	parameter DATA_BIT_WIDTH = 32;
	parameter TRUE_ADDR_BIT_WIDTH = 11;
	parameter N_WORDS = (1 << TRUE_ADDR_BIT_WIDTH);

	input clk, wrtEn;
	input[ADDR_BIT_WIDTH - 1 : 0] addr;
	inout [DATA_BIT_WIDTH - 1 : 0] dbus;
	/*input [3:0] key;
	input [9:0] sw;
	input [ADDR_BIT_WIDTH - 1 : 0] addr;
	input [DATA_BIT_WIDTH - 1 : 0] dIn;
	output [DATA_BIT_WIDTH - 1 : 0] dOut;
	output reg [9:0] ledr;
	output reg [7:0] ledg;
	output reg [15:0] hex;
	*/

	(* ram_init_file = MEM_INIT_FILE *)
	reg [DATA_BIT_WIDTH - 1 : 0] data [0 : N_WORDS - 1];
	/*reg [TRUE_ADDR_BIT_WIDTH - 1 :0] addr_reg;
	reg [DATA_BIT_WIDTH - 1 : 0] sw_reg;
	reg [DATA_BIT_WIDTH - 1 : 0] key_reg;
	*/

	always @(posedge clk) begin
		if (wrtEn && addr[28]==1'b0)
			data[addr[TRUE_ADDR_BIT_WIDTH+2:2]] <= dbus;
   end
	 
	assign dbus = (!wrtEn && addr[28]==1'b0) ? 
	 data[addr[TRUE_ADDR_BIT_WIDTH + 2 : 2]] : 32'd0;
	
	/*always @(negedge clk) begin
		if (wrtEn && !addr[29]) data[addr[13:2]] <= dIn;
		addr_reg <= addr[13:2];
	end
	*/

	//assign dOut = addr[29] ? (addr[2] ? sw_reg : key_reg) : data[addr_reg];
endmodule
