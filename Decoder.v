module Decoder (
    input  logic [31:0] Instr,

    output logic        PCS,
    output logic        RegW,
    output logic        MemW,
    output logic        MemtoReg,
    output logic        AluSr,
    output logic [1:0]  ImmSrc,
    output logic [1:0]  RegSrc,
    output logic [2:0]  ALUControl,
    output logic [2:0]  FlagW,
    output logic        Valid
);

    logic Branch;
    logic ALUOp;

    logic MainValid;
    logic ALUValid;
    logic FormatValid;

    logic RegW_raw;
    logic MemW_raw;
    logic MemtoReg_raw;
    logic ALUSrc_raw;
    logic PCS_raw;

    logic [1:0] ImmSrc_raw;
    logic [1:0] RegSrc_raw;
    logic [2:0] ALUControl_raw;
    logic [2:0] FlagW_raw;

    Main_Decoder main_decoder (
        .Op       (Instr[27:26]),
        .Funct    (Instr[25:20]),

        .RegW     (RegW_raw),
        .MemW     (MemW_raw),
        .MemtoReg (MemtoReg_raw),
        .ALUSrc   (ALUSrc_raw),
        .ImmSrc   (ImmSrc_raw),
        .RegSrc   (RegSrc_raw),
        .Branch   (Branch),
        .ALUOp    (ALUOp),
        .Valid    (MainValid)
    );

    ALU_Decoder alu_decoder (
        .Funct      (Instr[24:20]),
        .ALUOp      (ALUOp),

        .ALUControl (ALUControl_raw),
        .FlagW      (FlagW_raw),
        .Valid      (ALUValid)
    );

    PC_Logic pc_logic (
        .Rd     (Instr[15:12]),
        .Branch (Branch),
        .RegW   (RegW_raw),
        .PCS    (PCS_raw)
    );

    // Kiem tra nhung dang lenh datapath chua ho tro
    always_comb begin
        FormatValid = 1'b1;

        if (Instr[27:26] == 2'b00) begin

            // Chua ho tro luong dich lay tu thanh ghi
            if (!Instr[25] && Instr[4])
                FormatValid = 1'b0;

            // MOV dung truong Rn = 0
            if (Instr[24:21] == 4'b1101 &&
                Instr[19:16] != 4'b0000)
                FormatValid = 1'b0;

            // S=1 va Rd=PC can co che exception return
            if (Instr[20] && Instr[15:12] == 4'd15)
                FormatValid = 1'b0;

        end
    end

    assign Valid = MainValid
                 & ALUValid
                 & FormatValid
                 & (Instr[31:28] != 4'hF);

    assign PCS  = Valid & PCS_raw;
    assign RegW = Valid & RegW_raw;
    assign MemW = Valid & MemW_raw;

    assign MemtoReg = Valid ? MemtoReg_raw : 1'b0;
    assign AluSr    = Valid ? ALUSrc_raw   : 1'b0;
    assign ImmSrc   = Valid ? ImmSrc_raw   : 2'b00;
    assign RegSrc   = Valid ? RegSrc_raw   : 2'b00;

    assign ALUControl = Valid ? ALUControl_raw : 3'b000;
    assign FlagW      = Valid ? FlagW_raw      : 3'b000;

endmodule