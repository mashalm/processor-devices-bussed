module PipeRegister(clk, rst, wrtEn, memWrtIn, memToRegIn, branchIn, jalIn, lwIn, regWrtIn, destRegIn, sextIn, aluIn, dataIn, pcIn, memWrtOut, memToRegOut, branchOut, jalOut, lwOut, regWrtOut, destRegOut, sextOut, aluOut, dataOut, pcOut);

	input clk, rst, wrtEn, memWrtIn, memToRegIn, branchIn, jalIn, lwIn, regWrtIn;
	input [3:0] destRegIn;
	input [31:0] sextIn, aluIn, dataIn, pcIn;

	output memWrtOut, memToRegOut, branchOut, jalOut, lwOut, regWrtOut;
	output [3:0] destRegOut;
	output [31:0] sextOut, aluOut, dataOut, pcOut;

	reg memWrtOut, memToRegOut, branchOut, jalOut, lwOut, regWrtOut;
	reg [3:0] destRegOut;
	reg [31:0] sextOut, aluOut, dataOut, pcOut;

	always @(posedge clk) begin
		if (wrtEn) begin
			memWrtOut <= memWrtIn;
			memToRegOut <= memToRegIn;
			branchOut <= branchIn;
			jalOut <= jalIn;
			lwOut <= lwIn;
			regWrtOut <= regWrtIn;
			destRegOut <= destRegIn;
			sextOut <= sextIn;
			aluOut <= aluIn;
			dataOut <= dataIn;
			pcOut <= pcIn;
		end
		if (rst) begin
			memWrtOut <= 1'b0;
			memToRegOut <= 1'b0;
			branchOut <= 1'b0;
			jalOut <= 1'b0;
			lwOut <= 1'b0;
			regWrtOut <= 1'b0;
			destRegOut <= 4'b0;
			sextOut <= 32'b0;
			aluOut <= 32'b0;
			dataOut <= 32'b0;
			pcOut <= 32'b0;
		end
	end

endmodule
