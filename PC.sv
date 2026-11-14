module PC_logic(
input logic [3:0] Rd,
input logic RegW,
input logic Branch,
output logic PCS
);
assign PCS = ((Rd == 4'b1111) & RegW)|Branch;
endmodule