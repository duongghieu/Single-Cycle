module datapath #(
    parameter MEMFILE = "mem.dat"
) (
    input  logic        clk,
    input  logic        reset,

    input  logic        PCSrc,
    input  logic        MemtoReg,
    input  logic        MemWrite,
    input  logic        ALUSrc,
    input  logic [2:0]  ALUControl,
    input  logic [1:0]  ImmSrc,
    input  logic        RegWrite,
    input  logic [1:0]  RegSrc,
    input  logic        CarryIn,

    output logic [31:0] Instr,
    output logic [31:0] PC,
    output logic [31:0] ALUResult,
    output logic [31:0] WriteData,
    output logic [31:0] ReadData,
    output logic [31:0] SrcA,
    output logic [31:0] SrcB,
    output logic [31:0] ExtImm,
    output logic [31:0] RD1,
    output logic [31:0] RD2,
    output logic [3:0]  ALUFlags
);

    logic [31:0] PCNext;
    logic [31:0] PCPlus4;
    logic [31:0] PCPlus8;
    logic [31:0] Result;

    logic [31:0] ShiftedRD2;

    logic ShiftCarry;
    logic ImmCarry;
    logic OperandCarry;

    logic [3:0] RA1;
    logic [3:0] RA2;

    // PC

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'b0;
        else
            PC <= PCNext;
    end

    assign PCPlus4 = PC + 32'd4;
    assign PCPlus8 = PC + 32'd8;

    assign PCNext = PCSrc
                  ? {Result[31:2], 2'b00}
                  : PCPlus4;

    // Instruction Memory

    Instruction_Memory #(
        .MEMFILE(MEMFILE)
    ) imem (
        .A  (PC),
        .RD (Instr)
    );

    // Chon dia chi thanh ghi

    mux #(.N(4)) muxA (
        .a   (Instr[19:16]),
        .b   (4'd15),
        .sel (RegSrc[0]),
        .y   (RA1)
    );

    mux #(.N(4)) muxB (
        .a   (Instr[3:0]),
        .b   (Instr[15:12]),
        .sel (RegSrc[1]),
        .y   (RA2)
    );
    // Register File

    Register_file rf (
        .clk   (clk),
        .reset (reset),
        .WE3   (RegWrite),

        .A1    (RA1),
        .A2    (RA2),
        .A3    (Instr[15:12]),

        .R15   (PCPlus8),
        .WD3   (Result),

        .RD1   (RD1),
        .RD2   (RD2)
    );

    assign SrcA      = RD1;
    assign WriteData = RD2;

    // Dich toan hang thanh ghi

    Shifter shifter_inst (
        .Value     (RD2),
        .ShiftType (Instr[6:5]),
        .Amount    (Instr[11:7]),
        .CarryIn   (CarryIn),

        .Result    (ShiftedRD2),
        .CarryOut  (ShiftCarry)
    );

    // Mo rong immediate
	
    extend ext (
        .Instr    (Instr[23:0]),
        .ImmSrc   (ImmSrc),
        .CarryIn  (CarryIn),

        .ExtImm   (ExtImm),
        .CarryOut (ImmCarry)
    );

    // Chon toan hang B

    mux #(.N(32)) muxSrcB (
        .a   (ShiftedRD2),
        .b   (ExtImm),
        .sel (ALUSrc),
        .y   (SrcB)
    );

    assign OperandCarry = ALUSrc
                        ? ImmCarry
                        : ShiftCarry;

    // ALU

    ALU ALU_inst (
        .A            (SrcA),
        .B            (SrcB),
        .ALUControl   (ALUControl),
        .ShifterCarry (OperandCarry),

        .ALUResult    (ALUResult),
        .ALUFlags     (ALUFlags)
    );

    // Data Memory

    datamem dmem (
        .clk      (clk),
        .WE       (MemWrite),
        .A        (ALUResult),
        .WD       (WriteData),
        .ReadData (ReadData)
    );
    // Chon du lieu ghi ve Register File

    mux #(.N(32)) muxResult (
        .a   (ALUResult),
        .b   (ReadData),
        .sel (MemtoReg),
        .y   (Result)
    );

endmodule