`timescale 1ns/1ps

// Testbench for the supplied 64-word mem.dat.
// Tests the sample mem.dat program and reset/replay.
// Covers ADD, SUB, AND, ORR, LSL/LSR and terminal B .
// LDR/STR and BEQ are tested separately in tb_reference.sv.
// Run from the directory containing mem.dat (or use run_top.do).
module tb_top;
    localparam integer CLK_PERIOD = 20; // 50 MHz
    localparam MEMFILE = "mem.dat";

    logic clk = 1'b0;
    logic reset = 1'b0;

    wire [31:0] Instr_out, PC_out, ALUResult_out;
    wire [31:0] WriteData_out, ReadData_out;
    wire [31:0] SrcA_out, SrcB_out, ExtImm_out, RD1_out, RD2_out;
    wire PCSrc_out, MemtoReg_out, MemWrite_out, RegWrite_out;
    wire [2:0] ALUControl_out;
    wire [1:0] ImmSrc_out, RegSrc_out;
    wire N_out, Z_out, C_out, V_out, InstrValid_out;
    wire [3:0] ALUFlags_out;

    logic [31:0] expected_rf [0:14];
    integer checks = 0;
    integer mem_handle;

    top #(.MEMFILE(MEMFILE)) dut (
        .clk(clk), .reset(reset),
        .Instr_out(Instr_out), .PC_out(PC_out),
        .ALUResult_out(ALUResult_out),
        .WriteData_out(WriteData_out), .ReadData_out(ReadData_out),
        .SrcA_out(SrcA_out), .SrcB_out(SrcB_out),
        .ExtImm_out(ExtImm_out), .RD1_out(RD1_out), .RD2_out(RD2_out),
        .PCSrc_out(PCSrc_out), .MemtoReg_out(MemtoReg_out),
        .MemWrite_out(MemWrite_out), .RegWrite_out(RegWrite_out),
        .ALUControl_out(ALUControl_out),
        .ImmSrc_out(ImmSrc_out), .RegSrc_out(RegSrc_out),
        .N_out(N_out), .Z_out(Z_out), .C_out(C_out), .V_out(V_out),
        .InstrValid_out(InstrValid_out), .ALUFlags_out(ALUFlags_out)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // Case inequality also detects unexpected X/Z in checked signals.
    task automatic check32(
        input string label_text,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        checks = checks + 1;
        if (actual !== expected)
            $fatal(1, "%s at %0t: got=%08h expected=%08h",
                   label_text, $time, actual, expected);
    endtask

    task automatic check_registers;
        for (int i = 0; i < 15; i = i + 1)
            check32($sformatf("R%0d", i),
                    dut.datapath_inst.rf.rf[i], expected_rf[i]);
    endtask

    task automatic reset_cpu;
        // Assert between clock edges to check asynchronous reset.
        @(negedge clk);
        #2;
        reset = 1'b1;
        for (int i = 0; i < 15; i = i + 1)
            expected_rf[i] = 32'b0;
        #1;
        check32("PC during reset", PC_out, 0);
        check32("NZCV during reset", {28'b0, N_out, Z_out, C_out, V_out}, 0);
        check32("RegWrite during reset", {31'b0, RegWrite_out}, 0);
        check32("MemWrite during reset", {31'b0, MemWrite_out}, 0);
        check32("PCSrc during reset", {31'b0, PCSrc_out}, 0);
        check_registers();

        repeat (2) @(posedge clk);
        #1; // Wait for nonblocking assignments to settle.
        check32("PC held in reset", PC_out, 0);
        check_registers();
        @(negedge clk);
        reset = 1'b0;
    endtask

    task automatic step(
        input logic [31:0] expected_pc,
        input logic [31:0] expected_instr,
        input logic [31:0] expected_a,
        input logic [31:0] expected_b,
        input logic [31:0] expected_result,
        input logic [2:0] expected_control,
        input logic [3:0] expected_alu_flags,
        input bit is_branch
    );
        // Check the current instruction BEFORE its execution edge.
        #1;
        check32("PC", PC_out, expected_pc);
        check32("Instr", Instr_out, expected_instr);
        check32("InstrValid", {31'b0, InstrValid_out}, 1);
        check32("SrcA", SrcA_out, expected_a);
        check32("SrcB", SrcB_out, expected_b);
        check32("ALUResult", ALUResult_out, expected_result);
        check32("ALUControl", {29'b0, ALUControl_out}, {29'b0, expected_control});
        check32("ALUFlags", {28'b0, ALUFlags_out}, {28'b0, expected_alu_flags});
        check32("PCSrc", {31'b0, PCSrc_out}, is_branch ? 32'd1 : 32'd0);
        check32("RegWrite", {31'b0, RegWrite_out}, is_branch ? 32'd0 : 32'd1);
        check32("MemWrite", {31'b0, MemWrite_out}, 0);
        check32("MemtoReg", {31'b0, MemtoReg_out}, 0);
        check32("ImmSrc", {30'b0, ImmSrc_out}, is_branch ? 32'd2 : 32'd0);
        check32("RegSrc", {30'b0, RegSrc_out}, is_branch ? 32'd1 : 32'd0);

        if (!is_branch)
            expected_rf[expected_instr[15:12]] = expected_result;

        @(posedge clk);
        #1; // Read AFTER sequential updates, avoiding a testbench race.
        check32("Next PC", PC_out,
                is_branch ? expected_result : expected_pc + 32'd4);
        check_registers();
        // All data-processing instructions in this mem.dat have S=0.
        check32("Saved NZCV unchanged", {28'b0, N_out, Z_out, C_out, V_out}, 0);
        $display("PASS PC=%08h Instr=%08h result=%08h",
                 expected_pc, expected_instr, expected_result);
    endtask

    task automatic run_program;
        //        PC  machine code    A   B  result  operation  ALU NZCV  B?
        step(32'h00, 32'hE08F000F,  8,  8, 16, 3'b000, 4'b0000, 0); // ADD R0,PC,PC
        step(32'h04, 32'hE2802005, 16,  5, 21, 3'b000, 4'b0000, 0); // ADD R2,R0,#5
        step(32'h08, 32'hE240300F, 16, 15,  1, 3'b001, 4'b0010, 0); // SUB R3,R0,#15
        step(32'h0C, 32'hE0037002,  1, 21,  1, 3'b010, 4'b0000, 0); // AND R7,R3,R2
        step(32'h10, 32'hE1874003,  1,  1,  1, 3'b011, 4'b0000, 0); // ORR R4,R7,R3
        step(32'h14, 32'hE1A08287, 16, 32, 32, 3'b101, 4'b0000, 0); // LSL R8,R7,#5
        step(32'h18, 32'hE1A09124, 16,  0,  0, 3'b101, 4'b0100, 0); // LSR R9,R4,#2

        repeat (4)
            step(32'h1C, 32'hEAFFFFFE, 36, 32'hFFFFFFF8,
                 28, 3'b000, 4'b0010, 1); // B .: PC+8-8 = PC
    endtask

    initial begin
        $timeformat(-9, 0, " ns", 10);
        mem_handle = $fopen(MEMFILE, "r");
        if (mem_handle == 0)
            $fatal(1, "Cannot open %s. Run from the repo root.", MEMFILE);
        $fclose(mem_handle);

        $display("=== TEST 1: reset and supplied mem.dat ===");
        reset_cpu();
        run_program();

        $display("=== TEST 2: reset after execution, then replay ===");
        reset_cpu();
        run_program();

        $display("ALL TESTS PASSED (%0d checks)", checks);
        $finish;
    end

    // Prevent a broken testbench/clock from running forever.
    initial begin
        #10000;
        $fatal(1, "TIMEOUT");
    end
endmodule
