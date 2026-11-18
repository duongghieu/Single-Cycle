module Main_decoder(
	input  logic [1:0] Op,
    input  logic [5:0] Funct,

    output logic       RegW,
    output logic       MemW,
    output logic       MemtoReg,
    output logic       ALUSrc,
    output logic [1:0] ImmSrc,
    output logic [1:0] RegSrc,
    output logic       Branch,
	output logic	   Valid,
    output logic       ALUOp
);
   always_comb begin
        RegW     = 1'b0;
        MemW     = 1'b0;
        MemtoReg = 1'b0;
        ALUSrc   = 1'b0;
        ImmSrc   = 2'b00;
        RegSrc   = 2'b00;
        Branch   = 1'b0;
        ALUOp    = 1'b0;
        Valid    = 1'b0;
		
		case (Op)
			
			2'b00: begin //data processing
				Valid = 1'b1;
				RegW = 1'b1;
				ALUOp = 1'b1;
				ALUSrc = Funct[5]; //Bit I
			end
			2'b01: begin //LDR/STR word
			//{I,P,U,B,w} = {0,1,1,0,0}
			// [Rn, #+imm12], khoong writeback
			case (Funct[5:1])
			
				5'b01100: begin
					Valid = 1'b1;
					ALUSrc = 1'b1;
					ImmSrc = 2'b01;
				if(Funct[0]) begin //LDR
					RegW = 1'b1;
					MemtoReg = 1'b1;
				end
				else begin //STR
					MemW = 1'b1;
					RegSrc = 2'b01;
				end
			end
			default: begin end
		endcase
		end
				2'b10: begin // B, chua ho tro BL
        case (Funct[5:4])

                2'b10: begin
                    Valid  = 1'b1;
                    Branch = 1'b1;
                    ALUSrc = 1'b1;
                    ImmSrc = 2'b10;
                    RegSrc = 2'b01; // Doc R15 = PC+8
                    end

                    default: begin end

        endcase
					end

            default: begin end

        endcase
    end

endmodule