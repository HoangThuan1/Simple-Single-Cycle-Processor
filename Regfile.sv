module Regfile (
	input  logic clk,
	input  logic reset,
	input  logic regwrite,
	input  logic [3:0] rs, rt, rd,
	input  logic [15:0] writedata,
	output logic [15:0] read1, read2
);

	logic [15:0] regs [0:15];
	integer i;

	assign read1 = regs[rs];
	assign read2 = regs[rt];

	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			for (i = 0; i < 16; i = i + 1)
				regs[i] <= 16'd0;
		end
		else if (regwrite && rd != 4'd0) begin
			regs[rd] <= writedata;
		end
	end

endmodule
