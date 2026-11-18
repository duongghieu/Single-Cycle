module Control_Unit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] Instr,
    input  logic [3:0]  ALUFlags,

    output logic        PCSrc,
    output logic        MemtoReg,
    output logic        MemWrite,
    output logic [2:0]  ALUControl,
    output logic [1:0]  ImmSrc,
    output logic        RegWrite,
    output logic        ALUSrc,
    output logic [1:0]  RegSrc,

    output logic [3:0]  SavedFlags,
    output logic        InstrValid
);

    logic PCS;
    logic RegW;
    logic MemW;
    logic CondEx;
    logic Execute;

    logic [2:0] FlagW;
    logic [2:0] FlagWrite;

    Decoder decoder_inst (
        .Instr      (Instr),

        .PCS        (PCS),
        .RegW       (RegW),
        .MemW       (MemW),
        .MemtoReg   (MemtoReg),
        .AluSr      (ALUSrc),
        .ImmSrc     (ImmSrc),
        .RegSrc     (RegSrc),
        .ALUControl (ALUControl),
        .FlagW      (FlagW),
        .Valid      (InstrValid)
    );

    Cond_check cond_check_inst (
        .Cond     (Instr[31:28]),
        .ALUFlags (SavedFlags),
        .CondEx   (CondEx)
    );

    assign Execute = InstrValid & CondEx & ~reset;

    assign PCSrc    = PCS  & Execute;
    assign RegWrite = RegW & Execute;
    assign MemWrite = MemW & Execute;

    assign FlagWrite = FlagW & {3{Execute}};

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            SavedFlags <= 4'b0000;
        end
        else begin

            // N, Z
            if (FlagWrite[2])
                SavedFlags[3:2] <= ALUFlags[3:2];

            // C
            if (FlagWrite[1])
                SavedFlags[1] <= ALUFlags[1];

            // V
            if (FlagWrite[0])
                SavedFlags[0] <= ALUFlags[0];

        end
    end

endmodule