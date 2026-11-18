module extend (
    input  logic [23:0] Instr,
    input  logic [1:0]  ImmSrc,
    input  logic        CarryIn,

    output logic [31:0] ExtImm,
    output logic        CarryOut
);

    logic [31:0] imm8;
    logic [4:0]  rotate_amount;

    always_comb begin
        imm8 = {24'b0, Instr[7:0]};

        // So bit xoay = 2 * rotate
        rotate_amount = {Instr[11:8], 1'b0};

        ExtImm   = 32'b0;
        CarryOut = CarryIn;

        case (ImmSrc)

            2'b00: begin // Data-processing immediate
                if (rotate_amount == 0) begin
                    ExtImm = imm8;
                end
                else begin
                    ExtImm = (imm8 >> rotate_amount)
                           | (imm8 << (32-rotate_amount));

                    CarryOut = ExtImm[31];
                end
            end

            2'b01: begin // Offset LDR/STR
                ExtImm = {20'b0, Instr[11:0]};
            end

            2'b10: begin // Offset branch co dau, nhan 4
                ExtImm = {{6{Instr[23]}}, Instr, 2'b00};
            end

            default: ExtImm = 32'b0;

        endcase
    end

endmodule