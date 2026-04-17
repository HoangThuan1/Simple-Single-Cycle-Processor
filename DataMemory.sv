module DataMemory (
	input logic clk,
	input logic memread, memwrite,
	input logic [15:0] addr,
	input logic [15:0] writedata,
	output logic [15:0] readdata
);

	logic [15:0] mem [0:255];

	always_ff @(posedge clk) begin
		if (memwrite)
			mem[addr[15:1]] <= writedata;
	end

	assign readdata = memread ? mem[addr[15:1]] : 16'd0;

endmodule