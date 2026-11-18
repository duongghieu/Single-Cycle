module Instruction_Memory #(
    parameter MEMFILE = "mem.dat"
) (
    input  logic [31:0] A,
    output logic [31:0] RD
);

    logic [31:0] mem [0:63];
    integer i;

    initial begin

        // Cac o chua dung chua lenh B .
        for (i = 0; i < 64; i = i + 1)
            mem[i] = 32'hEAFFFFFE;

        $readmemh(MEMFILE, mem);

    end

    always_comb begin
        if (A[31:8] == 0 && A[1:0] == 0)
            RD = mem[A[7:2]];
        else
            RD = 32'hEAFFFFFE;
    end

endmodule