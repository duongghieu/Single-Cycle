module top #(
    parameter MEMFILE = "mem.dat"
) (
    input  logic        clk,
    input  logic        reset,

    output logic [31:0] Instr_out,
    output logic [31:0] PC_out,
    output logic [31:0] ALUResult_out,
    output logic [31:0] WriteData_out,
    output logic [31:0] ReadData_out,

    output logic [31:0] SrcA_out,
    output logic [31:0] SrcB_out,
    output logic [31:0] ExtImm_out,
    output logic [31:0] RD1_out,
    output logic [31:0] RD2_out,

    output logic        PCSrc_out,
    output logic        MemtoReg_out,
    output logic        MemWrite_out,
    output logic        RegWrite_out,

    output logic [2:0]  ALUControl_out,
    output logic [1:0]  ImmSrc_out,
    output logic [1:0]  RegSrc_out,

    output logic        N_out,
    output logic        Z_out,
    output logic        C_out,
    output logic        V_out,

    output logic        InstrValid_out,
    output logic [3:0]  ALUFlags_out
);

    logic PCSrc;
    logic MemtoReg;
    logic MemWrite;
    logic RegWrite;
    logic ALUSrc;

    logic [2:0] ALUControl;
    logic [1:0] ImmSrc;
    logic [1:0] RegSrc;

    logic [31:0] Instr;
    logic [31:0] PC;
    logic [31:0] ALUResult;
    logic [31:0] WriteData;
    logic [31:0] ReadData;

    logic [31:0] SrcA;
    logic [31:0] SrcB;
    logic [31:0] ExtImm;
    logic [31:0] RD1;
    logic [31:0] RD2;

    logic [3:0] ALUFlags;
    logic [3:0] SavedFlags;

    logic InstrValid;


    // Datapath


    datapath #(
        .MEMFILE(MEMFILE)
    ) datapath_inst (
        .clk        (clk),
        .reset      (reset),

        .PCSrc      (PCSrc),
        .MemtoReg   (MemtoReg),
        .MemWrite   (MemWrite),
        .ALUSrc     (ALUSrc),
        .ALUControl (ALUControl),
        .ImmSrc     (ImmSrc),
        .RegWrite   (RegWrite),
        .RegSrc     (RegSrc),

        .CarryIn    (SavedFlags[1]),

        .Instr      (Instr),
        .PC         (PC),
        .ALUResult  (ALUResult),
        .WriteData  (WriteData),
        .ReadData   (ReadData),

        .SrcA       (SrcA),
        .SrcB       (SrcB),
        .ExtImm     (ExtImm),
        .RD1        (RD1),
        .RD2        (RD2),
        .ALUFlags   (ALUFlags)
    );


    // Control Unit


    Control_Unit control_inst (
        .clk        (clk),
        .reset      (reset),
        .Instr      (Instr),
        .ALUFlags   (ALUFlags),

        .PCSrc      (PCSrc),
        .MemtoReg   (MemtoReg),
        .MemWrite   (MemWrite),
        .ALUControl (ALUControl),
        .ImmSrc     (ImmSrc),
        .RegWrite   (RegWrite),
        .ALUSrc     (ALUSrc),
        .RegSrc     (RegSrc),

        .SavedFlags (SavedFlags),
        .InstrValid (InstrValid)
    );

    // Dau ra quan sat

    assign Instr_out     = Instr;
    assign PC_out        = PC;
    assign ALUResult_out = ALUResult;
    assign WriteData_out = WriteData;
    assign ReadData_out  = ReadData;

    assign SrcA_out   = SrcA;
    assign SrcB_out   = SrcB;
    assign ExtImm_out = ExtImm;
    assign RD1_out    = RD1;
    assign RD2_out    = RD2;

    assign PCSrc_out      = PCSrc;
    assign MemtoReg_out   = MemtoReg;
    assign MemWrite_out   = MemWrite;
    assign RegWrite_out   = RegWrite;
    assign ALUControl_out = ALUControl;
    assign ImmSrc_out     = ImmSrc;
    assign RegSrc_out     = RegSrc;

    // Co da luu trong thanh ghi trang thai
    assign {N_out, Z_out, C_out, V_out} = SavedFlags;

    // Co to hop tu phep tinh hien tai
    assign ALUFlags_out = ALUFlags;

    assign InstrValid_out = InstrValid;

endmodule