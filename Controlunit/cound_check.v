module Cond_check (
    input  logic [3:0] Cond,
    input  logic [3:0] ALUFlags, // Phai noi voi CO DA LUU
    output logic       CondEx
);

    always_comb begin
        case (Cond)

            4'h0: CondEx =  ALUFlags[2]; // EQ
            4'h1: CondEx = ~ALUFlags[2]; // NE

            4'h2: CondEx =  ALUFlags[1]; // CS
            4'h3: CondEx = ~ALUFlags[1]; // CC

            4'h4: CondEx =  ALUFlags[3]; // MI
            4'h5: CondEx = ~ALUFlags[3]; // PL

            4'h6: CondEx =  ALUFlags[0]; // VS
            4'h7: CondEx = ~ALUFlags[0]; // VC

            4'h8: CondEx = ALUFlags[1] & ~ALUFlags[2]; // HI
            4'h9: CondEx = ~ALUFlags[1] | ALUFlags[2]; // LS

            4'hA: CondEx = ~(ALUFlags[3] ^ ALUFlags[0]); // GE
            4'hB: CondEx =   ALUFlags[3] ^ ALUFlags[0];  // LT

            4'hC: CondEx = ~ALUFlags[2]
                         & ~(ALUFlags[3] ^ ALUFlags[0]); // GT

            4'hD: CondEx = ALUFlags[2]
                         | (ALUFlags[3] ^ ALUFlags[0]); // LE

            4'hE: CondEx = 1'b1; // AL

            default: CondEx = 1'b0;

        endcase
    end

endmodule