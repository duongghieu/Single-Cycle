module ALU_decoder(
input logic [4:0] Funct, //opcode[3:0], S
input logic 	  ALUOp,
output logic [2:0] ALUControl,
output logic [2:0] FlagW, // [2]=NZ, [1]=C, [0]=V
output logic Valid
);
always_comb begin
ALUControl = 3'b000;
FlagW	   = 3'b000;
Valid	   = 1'b1;

if(ALUOp) begin 
	case(Funct[4:1])
		4'b0100: begin //ADD
			ALUControl = 3'b000;
			if(Funct[0])
				FlagW = 3'b111;
		end
		4'b0010: begin //SUB
			ALUControl = 3'b001;
			if(Funct[0])
				FlagW = 3'b111;
		end
		4'b0000: begin //AND
			ALUControl = 3'b010;
			if(Funct[0])
				FlagW = 3'b0110;
		end
		4'b1100: begin //ORR
			ALUControl = 3'b011;
			if(Funct[0])
				FlagW = 3'b0110;
		end
		4'b0001: begin // EOR
                ALUControl = 3'b100;
            if (Funct[0])
                FlagW = 3'b110;
        end

        4'b1101: begin // MOV; LSL/LSR dung MOV + Shifter
                ALUControl = 3'b101;
            if (Funct[0])
                FlagW = 3'b110;
        end
		
		default: begin
			Valid = 1'b0;
		end
		
	endcase
	end
end
endmodule
	
