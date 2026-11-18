module Shifter (
    input  logic [31:0] Value,
    input  logic [1:0]  ShiftType,
    input  logic [4:0]  Amount,
    input  logic        CarryIn,

    output logic [31:0] Result,
    output logic        CarryOut
);

    always_comb begin
        Result   = Value;
        CarryOut = CarryIn;

        case (ShiftType)

            2'b00: begin // LSL
                // LSL #0: giu nguyen Value va Carry
                if (Amount != 0) begin
                    Result   = Value << Amount;
                    CarryOut = Value[32-Amount];
                end
            end

            2'b01: begin // LSR
                // Amount ma hoa bang 0 nghia la LSR #32
                if (Amount == 0) begin
                    Result   = 32'b0;
                    CarryOut = Value[31];
                end
                else begin
                    Result   = Value >> Amount;
                    CarryOut = Value[Amount-1];
                end
            end

            2'b10: begin // ASR
                // Amount ma hoa bang 0 nghia la ASR #32
                if (Amount == 0) begin
                    Result   = {32{Value[31]}};
                    CarryOut = Value[31];
                end
                else begin
                    Result   = $signed(Value) >>> Amount;
                    CarryOut = Value[Amount-1];
                end
            end

            2'b11: begin
                if (Amount == 0) begin // RRX
                    Result   = {CarryIn, Value[31:1]};
                    CarryOut = Value[0];
                end
                else begin // ROR
                    Result = (Value >> Amount)
                           | (Value << (32-Amount));

                    CarryOut = Result[31];
                end
            end

            default: begin end

        endcase
    end

endmodule