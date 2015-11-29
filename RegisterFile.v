module RegisterFile(clk, rst, wrtEn, wrtEnOut, wrtR, dIn, dr, sr1, sr2, sr1Out, sr2Out, busy1, busy2, forward1, forward2);
	parameter BIT_WIDTH = 32;
	parameter REG_WIDTH = 4;
	parameter REG_SIZE = (1 << REG_WIDTH);

	input clk, wrtEn, wrtEnOut, rst;
	input [BIT_WIDTH - 1 : 0] dIn;
	input [REG_WIDTH - 1 : 0] wrtR, dr, sr1, sr2;
	output busy1, busy2, forward1, forward2;
	output [BIT_WIDTH - 1 : 0] sr1Out, sr2Out;

	reg [BIT_WIDTH - 1 : 0] regs [0 : REG_SIZE - 1];
	reg busy [0 : REG_SIZE - 1];

	always @(posedge clk) begin
		if (wrtEnOut) begin
			regs[dr] <= dIn;
			busy[dr] <= 0;
		end
		if(wrtEn) begin
			busy[wrtR] <= rst ? 1'b0 : 1'b1;
		end
	end

	assign sr1Out = regs[sr1];
	assign sr2Out = regs[sr2];
	assign busy1 = busy[sr1];
	assign busy2 = busy[sr2];
	assign forward1 = busy[sr1] && (dr == sr1) ? 1'b1 : 1'b0;
	assign forward2 = busy[sr2] && (dr == sr2) ? 1'b1 : 1'b0;
endmodule
