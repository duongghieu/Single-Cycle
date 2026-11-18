module instruction memory(
input logic [31:0] A,
output logic [31:0] RD
);
// 64 word mỗi word 32-bit
logic [31:0] mem[63:0];
integer i;
initial begin
for(i=0; i < 64; i = i+1) begin
	mem [i] = 32'hEAFFFFFE;
end
$readmemh(
"D:/.../...////",
mem
);
end
always_comb begin
if ((A[1:0]==2'b00))&& (A[31:2]< 32'd64))
	RD = mem[A[31:2]];
	end
else
	RD = 32'hEAFFFFF;
	end
end
endmodule
	