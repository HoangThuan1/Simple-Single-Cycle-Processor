module ProgramCounter (
	input logic clk, reset,
	output logic [15:0] pc
);

	always_ff @(posedge clk or posedge reset) begin
		if (reset) pc <= 16'd0;
		else pc <= pc + 16'd2;
	end
	
endmodule
