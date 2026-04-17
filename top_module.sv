module top_module (
	input logic clk, reset
);

	// PC & Instruction
	logic [15:0] pc;
	logic [15:0] instr;

	ProgramCounter PC (
		.clk   (clk),
		.reset(reset),
		.pc    (pc)
	);

	InstructionMemory IM (
		.pc    (pc),
		.instr (instr)
	);

	// Instruction fields
	logic [3:0] opcode, rd, rs, rt;
	assign opcode = instr[15:12];
	assign rd     = instr[11:8];
	assign rs     = instr[7:4];
	assign rt     = instr[3:0];

	// Control signals
	logic regwrite;
	logic alusrc;
	logic memread;
	logic memwrite;
	logic memtoreg;
	logic [2:0] aluctrl;

	ControlUnit CU (
		.opcode  (opcode),
		.regwrite(regwrite),
		.alusrc  (alusrc),
		.memread (memread),
		.memwrite(memwrite),
		.memtoreg(memtoreg),
		.aluctrl   (aluctrl)
	);

	// Register File
	logic [15:0] read1, read2;
	logic [15:0] writedata;

	Regfile RF (
		.clk       (clk),
		.reset     (reset),
		.regwrite  (regwrite),
		.rs        (rs),
		.rt        (rt),
		.rd        (rd),
		.writedata (writedata),
		.read1     (read1),
		.read2     (read2)
	);

	// ALU input MUX
	logic [15:0] imm_ext;
	logic [15:0] alu_in2;

	assign imm_ext = {{12{instr[3]}}, instr[3:0]};
	assign alu_in2 = alusrc ? imm_ext : read2;

	// ALU
	logic [15:0] alu_result;
	logic        zero;

	ALU alu (
		.A      (read1),
		.B      (alu_in2),
		.aluctrl (aluctrl),
		.result(alu_result),
		.zero  (zero)
	);

	// Data Memory
	logic [15:0] mem_data;

	DataMemory DM (
		.clk       (clk),
		.memread  (memread),
		.memwrite (memwrite),
		.addr      (alu_result),
		.writedata (read2),
		.readdata  (mem_data)
	);

	// Write Back MUX
	assign writedata = memtoreg ? mem_data : alu_result;

endmodule
