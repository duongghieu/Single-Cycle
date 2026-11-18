module ALU (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic [2:0]  ALUControl,
    input  logic        ShifterCarry,

    output logic [31:0] ALUResult,
    output logic [3:0]  ALUFlags
);

    logic [32:0] temp;

    always_comb begin
        temp        = 33'b0;
        ALUResult   = 32'b0;
        ALUFlags    = 4'b0000;

        // Dung cho cac phep logic/MOV
        ALUFlags[1] = ShifterCarry;

        case (ALUControl)

            3'b000: begin // ADD
                temp = {1'b0, A} + {1'b0, B};

                ALUResult   = temp[31:0];
                ALUFlags[1] = temp[32];

                ALUFlags[0] = ~(A[31] ^ B[31])
                            & (A[31] ^ ALUResult[31]);
            end

            3'b001: begin // SUB
                temp = {1'b0, A}
                     + {1'b0, ~B}
                     + 33'd1;

                ALUResult = temp[31:0];

                // ARM: C=1 khi khong muon
                ALUFlags[1] = temp[32];

                ALUFlags[0] = (A[31] ^ B[31])
                            & (A[31] ^ ALUResult[31]);
            end

            3'b010: ALUResult = A & B; // AND
            3'b011: ALUResult = A | B; // ORR
            3'b100: ALUResult = A ^ B; // EOR

            // B da duoc dich truoc khi vao ALU
            3'b101: ALUResult = B;     // MOV

            default: ALUResult = 32'b0;

        endcase

        ALUFlags[3] = ALUResult[31];
        ALUFlags[2] = (ALUResult == 32'b0);

        // Lenh logic giu V cu thong qua FlagW[0]=0
    end

endmodule