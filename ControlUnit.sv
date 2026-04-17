module ControlUnit (
	input logic [3:0] opcode,
	output logic regwrite,
	output logic alusrc,
	output logic memread,
	output logic memwrite,
	output logic memtoreg,
	output logic [2:0] aluctrl
);

	always_comb begin
		regwrite = 0;
		alusrc   = 0;
		memread  = 0;
		memwrite = 0;
		memtoreg = 0;
		aluctrl = 3'b000;

		case (opcode)
			4'b0001: begin // ADD
				regwrite = 1;
				aluctrl  = 3'b000;
			end

			4'b0010: begin // SUB
				regwrite = 1;
				aluctrl  = 3'b001;
			end

			4'b0011: begin // AND
				regwrite = 1;
				aluctrl  = 3'b010;
			end

			4'b0100: begin // OR
				regwrite = 1;
				aluctrl  = 3'b011;
			end

			4'b0101: begin // SHL
				regwrite = 1;
				alusrc   = 1;
				aluctrl  = 3'b100;
			end

			4'b0110: begin // SHR
				regwrite = 1;
				alusrc   = 1;
				aluctrl  = 3'b101;
			end

			4'b0111: begin // LOADI
				regwrite = 1;
				alusrc   = 1;
				aluctrl  = 3'b000;     // ADD với r0
			end

			4'b1000: begin // STORE
				alusrc   = 1;
				memwrite = 1;
				aluctrl  = 3'b000;     // tính địa chỉ
			end
			
			4'b1001: begin // LOAD
				regwrite = 1;
				alusrc   = 1;
				memread  = 1;
				memtoreg = 1;
				aluctrl  = 3'b000; // ADD tính địa chỉ
			end

		endcase
	end

endmodule