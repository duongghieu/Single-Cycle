module register_file(
input logic clk,
input logic reset,
input logic WE3,

input logic [3:0] A1,
input logic [3:0] A2,
input logic [3:0] A3,

output logic [31:0] RD1,
output logic [31:0] RD2,

output logic [31:0] R15,
output logic [31:0] WD3
);
//16 register: R0:R14
logic [31:0] rf [0:14];
integer i;
always_comb begin 
RD1 = (A1 == 4'd15) ? R15 : rf[A1];
RD2 = (A2 == 4'd15) ? R15 : rf[A2];
end
always_ff @(posedge clk or posedge reset) begin
if(reset) begin
	for(i=0;i<16;i++) begin
		rf[i] <= 32'b0;
			end
end
else if (WE3 && (A3 != 4'd15)) begin
	rf[A3] = WD3;
	end
end
endmodule