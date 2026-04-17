module InstructionMemory (
	input  logic [15:0] pc,
   output logic [15:0] instr
);

   // 64 instructions (16-bit)
   logic [15:0] rom [0:63];

   // chương trình mẫu
   initial begin      
		rom[0] = 16'b0111_0001_0000_0101; // LOADI R1, #5
		rom[1] = 16'b0111_0010_0000_0011; // LOADI R2, #3
		rom[2] = 16'b0001_0011_0001_0010; // ADD R3, R1, R2
		rom[3] = 16'b0010_0100_0001_0010; // SUB R4, R1, R2
		rom[4] = 16'b0011_0101_0001_0010; // AND R5, R1, R2
		rom[5] = 16'b0100_0110_0001_0010; // OR  R6, R1, R2
   end

   // fetch instruction (PC byte-addressed, instr = 2 bytes)
   assign instr = rom[pc[15:1]];

endmodule
