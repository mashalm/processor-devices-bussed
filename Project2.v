module Project2(SW,KEY,LEDR,LEDG,HEX0,HEX1,HEX2,HEX3,CLOCK_50);
	input  [9:0] SW;
	input  [3:0] KEY;
	input  CLOCK_50;
	output [9:0] LEDR;
	output [7:0] LEDG;
	output [6:0] HEX0,HEX1,HEX2,HEX3;

	parameter ADDR_KEY						= 32'hF0000010;
	parameter ADDR_SW							= 32'hF0000014;
	parameter ADDR_HEX						= 32'hF0000000;
	parameter ADDR_LEDR						= 32'hF0000004;
	parameter ADDR_LEDG						= 32'hF0000008;


	parameter DBITS							= 32;
	parameter INST_BIT_WIDTH				= 32;
	parameter START_PC						= 32'h40;
	parameter REG_INDEX_BIT_WIDTH			= 4;

	parameter IMEM_INIT_FILE				= "Test2.mif";

	parameter IMEM_ADDR_BIT_WIDTH			= 11;
	parameter IMEM_DATA_BIT_WIDTH			= INST_BIT_WIDTH;
	parameter TRUE_DMEM_ADDR_BIT_WIDTH	= 11;
	parameter DMEM_ADDR_BIT_WIDTH			= INST_BIT_WIDTH - 2;
	parameter DMEM_DATA_BIT_WIDTH			= INST_BIT_WIDTH;
	parameter IMEM_PC_BITS_HI				= IMEM_ADDR_BIT_WIDTH + 2;
	parameter IMEM_PC_BITS_LO				= 2;
	
	parameter HEX_ADDR 						= 32'hF000_0000;
	parameter KEY_ADDR 						= 32'hF000_0010;
	parameter KCTRL_ADDR 					= 32'hF000_0110;
	parameter SWITCH_ADDR 					= 32'hF000_0014;
	parameter SWCTRL_ADDR 					= 32'hF000_0114;
	parameter LEDR_ADDR 						= 32'hF000_0004;
	parameter LEDG_ADDR 						= 32'hF000_0008;
	parameter TCOUNT_ADDR 					= 32'hF000_0020;
	parameter TLIM_ADDR 						= 32'hF000_0024;
	parameter TCTRL_ADDR 					= 32'hF000_0120;

	//PLL, clock genration, and reset generation
	wire clk, lock;
	PLL	PLL_inst (.inclk0 (CLOCK_50),.c0 (clk),.locked (lock));
	wire reset = ~lock;
	
	// Wires..
	wire memtoReg, memWrite, branch, jal, lw, alusrc, regWrite, memWrtOut, memToRegOut, branchOut, jalOut, lwOut, regWrtOut, busy1, busy2, forward1, forward2, rst;
	wire pcWrtEn = ~lwOut || (~busy1 && ~busy2);
	wire [3:0] destRegOut;
	wire [7:0] aluControl, ledg;
	wire [9:0] ledr;
	wire [15:0] hex;
	wire [IMEM_DATA_BIT_WIDTH - 1 : 0] instWord;
	wire [DBITS - 1 : 0] pcIn, pcOut, incrementedPC, pcAdderOut, aluOut, signExtImm, dataMuxOut, sr1Out, sr2Out, sr1OutUnForwarded, sr2OutUnForwarded, aluMuxOut, memDataOut, sextOut, aluOutOut, dataOut, pcOutOut;
	//for bussing:
	wire [DBITS-1: 0] address;
	tri [DBITS-1: 0] dbus;
	
	
	// Create PCMUX
	Mux3to1 #(DBITS) pcMux (
		.sel({jalOut, (branchOut & aluOutOut[0])}),
		.dInSrc1(incrementedPC),
		.dInSrc2(pcAdderOut),
		.dInSrc3(aluOutOut),
		.dOut(pcIn)
	);

	// This PC instantiation is your starting point
	Register #(DBITS, START_PC) pc (
		.clk(clk),
		.reset(reset),
		.wrtEn(pcWrtEn),
		.dataIn(pcIn),
		.dataOut(pcOut)
	);

	// Create PC Increament (PC + 4)
	PCIncrement pcIncrement (
		.dIn(pcOut),
		.dOut(incrementedPC)
	);

	// Create Instruction Memory
	InstMemory #(IMEM_INIT_FILE, IMEM_ADDR_BIT_WIDTH, IMEM_DATA_BIT_WIDTH) instMemory (
		.addr(pcOut[IMEM_PC_BITS_HI - 1 : IMEM_PC_BITS_LO]),
		.dataOut(instWord)
	);

	wire [13:0] ctrl;
	// Create Controller(SCProcController)
	SCProcController controller (
		.opcode({instWord[3:0],instWord[7:4]}),
		.aluControl(aluControl),
		.memtoReg(memtoReg),
		.memWrite(memWrite),
		.branch(branch),
		.jal(jal),
		.alusrc(alusrc),
		.regWrite(regWrite),
		.lw(lw),
		.ctrl(ctrl)
	);

	// Create State Register
	PipeRegister pipe(
		.clk(clk),
		.rst(rst | reset),
		.wrtEn(pcWrtEn),
		.memWrtIn(memWrite),
		.memToRegIn(memtoReg),
		.branchIn(branch),
		.jalIn(jal),
		.lwIn(lw),
		.regWrtIn(regWrite),
		.destRegIn(instWord[31:28]),
		.sextIn(signExtImm),
		.aluIn(aluOut),
		.dataIn(sr2Out),
		.pcIn(incrementedPC),
		.memWrtOut(memWrtOut),
		.memToRegOut(memToRegOut),
		.branchOut(branchOut),
		.jalOut(jalOut),
		.lwOut(lwOut),
		.regWrtOut(regWrtOut),
		.destRegOut(destRegOut),
		.sextOut(sextOut),
		.aluOut(aluOutOut),
		.dataOut(dataOut),
		.pcOut(pcOutOut)
	);
	
	assign address = aluOutOut;
	assign dbus = memWrtOut ? dataOut : {DBITS{1'bz}};
	
	// Create SignExtension
	SignExtension #(16, DBITS) signExtension (
		.dIn(instWord[23:8]),
		.dOut(signExtImm)
	);

	// Create pcAdder (incrementedPC + signExtImm << 2)
	PCAdder pcAdder (
		.dIn1(pcOutOut),
		.dIn2(sextOut),
		.dOut(pcAdderOut)
	);

	// Create Dual Ported Register File
	RegisterFile #(DBITS, REG_INDEX_BIT_WIDTH) dprf (
		.clk(clk),
		.rst(rst),
		.wrtEn(regWrite),
		.wrtEnOut(regWrtOut),
		.wrtR(instWord[31:28]),
		.dIn(dataMuxOut),
		.dr(destRegOut),
		.sr1(memWrite | branch ? instWord[31:28] : instWord[27:24]),
		.sr2(memWrite | branch ? instWord[27:24] : instWord[23:20]),
		.sr1Out(sr1OutUnForwarded),
		.sr2Out(sr2OutUnForwarded),
		.busy1(busy1),
		.busy2(busy2),
		.forward1(forward1),
		.forward2(forward2)
	);

	// Create forward1 Mux
	Mux2to1 #(DBITS) forward1Mux (
		.sel(forward1),
		.dInSrc1(sr1OutUnForwarded),
		.dInSrc2(aluOutOut),
		.dOut(sr1Out)
	);

	// Create forward2 Mux
	Mux2to1 #(DBITS) forward2Mux (
		.sel(forward2),
		.dInSrc1(sr2OutUnForwarded),
		.dInSrc2(aluOutOut),
		.dOut(sr2Out)
	);

	// Create AluMux (Between DPRF and ALU)
	Mux2to1 #(DBITS) aluMux (
		.sel(alusrc),
		.dInSrc1(sr2Out),
		.dInSrc2(signExtImm),
		.dOut(aluMuxOut)
	);

	// Create ALU
	ALU alu (
		.dIn1(sr1Out),
		.dIn2(aluMuxOut),
		.op1(aluControl[7:4]),
		.op2(aluControl[3:0]),
		.dOut(aluOut)
	);

	// Create DataMemory
	DataMemory #(IMEM_INIT_FILE, DMEM_ADDR_BIT_WIDTH, DMEM_DATA_BIT_WIDTH, TRUE_DMEM_ADDR_BIT_WIDTH) dataMemory (
		.clk(clk),
		.wrtEn(memWrtOut),
		.addr(address),
		.dbus(dbus)
		/*.addr(aluOutOut),
		.dIn(dataOut),
		.sw(SW),
		.key(KEY),
		.ledr(ledr),
		.ledg(ledg),
		.hex(hex),
		.dOut(memDataOut)
		*/
	);
	
	//-----make sure to add params!----
	Timer #(.DBITS(DBITS),
	.CNTBASE(TCOUNT_ADDR),
	.LIMBASE(TLIM_ADDR),
	.CTRLBASE(TCTRL_ADDR),
	.CLKDIV(10000)) timer(
		.clk(clk), 
		.reset(reset), 
		.dbus(dbus),
		.address(address), 
		.wrtEn(memWrtOut)
	);
	
	KeyController #(.DBITS(DBITS), .MY_NAMESPACE(KEY_ADDR),
	.KCTRL_ADDR(KCTRL_ADDR)) keycont(
		.clk(clk), 
		.reset(reset),
		.dbus(dbus), 
		.address(address), 
		.wrtEn(memWrtOut), 
		.keys(KEY)
	);

	HexController #(.DBITS(DBITS),
	.MY_NAMESPACE(HEX_ADDR)) hexcont(
		.clk(clk),
		.reset(reset), 
		.dbus(dbus), 
		.address(address), 
		.wrtEn(memWrtOut), 
		.HEX0(HEX0), 
		.HEX1(HEX1), 
		.HEX2(HEX2), 
		.HEX3(HEX3)
	);
	
	LEDController #(.DBITS(DBITS), .LBITS(10), 
	.LED_NAMESPACE(LEDR_ADDR)) ledrcont(
		.clk(clk), 
		.reset(reset), 
		.dbus(dbus), 
		.address(address), 
		.wrtEn(memWrtOut), 
		.led(LEDR)
	);
	
	LEDController #(.DBITS(DBITS), .LBITS(8), 
	.LED_NAMESPACE(LEDG_ADDR)) ledgcont(
		.clk(clk), 
		.reset(reset), 
		.dbus(dbus), 
		.address(address), 
		.wrtEn(memWrtOut), 
		.led(LEDG)
	);
	
	SwitchController #(.DBITS(DBITS), 
	.SW_NAMESPACE(SWITCH_ADDR), 
	.SWCTRL_ADDR(SWCTRL_ADDR),
	.DEBOUNCE_COUNT(100000)) switchcont(
		.clk(clk), 
		.reset(reset), 
		.wrtEn(memWrtOut), 
		.dbus(dbus), 
		.address(address), 
		.switches(SW)
	);
	

	// Create dataMux
	Mux3to1 #(DBITS) dataMux (
		.sel({jalOut, memToRegOut}),
		.dInSrc1(aluOutOut),
		.dInSrc2(dbus),
		.dInSrc3(pcOutOut),
		.dOut(dataMuxOut)
	);
	
	
	//assign LEDR = ledr;
	//assign LEDG = ledg;
	assign rst = (lwOut & (forward1 | forward2)) || jalOut || (branchOut & aluOutOut[0]);

endmodule
