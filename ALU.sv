module ALU (
	input  logic [15:0] A, B,
	input  logic [2:0]  aluctrl,
	output logic [15:0] result,
	output logic zero
);

	always_comb begin
		case (aluctrl)
			3'b000: result = A + B;
			3'b001: result = A - B;
			3'b010: result = A & B;
			3'b011: result = A | B;
			3'b100: result = A << B[3:0];
			3'b101: result = A >> B[3:0];
			default: result = 16'd0;
		endcase
	end

	assign zero = (result == 16'd0);

endmodule