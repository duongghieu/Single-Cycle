`timescale 1ns/1ps
module tb_reference;
    reg clk=0;
    reg reset=1;
    wire [31:0] Instr_out,PC_out,ALUResult_out,WriteData_out,ReadData_out;
    wire RegWrite_out,MemWrite_out,PCSrc_out,MemtoReg_out,InstrValid_out;
    wire N_out,Z_out,C_out,V_out;
    integer epoch,cycle,r,m,k,report_file;
    integer coverage_count [0:6];
    integer beq_taken=0,beq_not_taken=0,skipped_store=0,skipped_register=0;
    integer invalid_load=0,invalid_store=0;
    integer carry_add=0,overflow_add=0,overflow_sub=0,sub_equal=0;
    integer logic_zero=0,logic_ones=0,logic_preserve_v=0;
    reg [1023:0] label_text;
    reg completed;

    always #5 clk=~clk;

    top #(.MEMFILE("tests/reference/program.dat")) dut (
        .clk(clk),.reset(reset),
        .Instr_out(Instr_out),.PC_out(PC_out),
        .ALUResult_out(ALUResult_out),.WriteData_out(WriteData_out),
        .ReadData_out(ReadData_out),.RegWrite_out(RegWrite_out),
        .MemWrite_out(MemWrite_out),.PCSrc_out(PCSrc_out),
        .MemtoReg_out(MemtoReg_out),.InstrValid_out(InstrValid_out),
        .N_out(N_out),.Z_out(Z_out),.C_out(C_out),.V_out(V_out)
    );
    reference_model model();
    scoreboard sb();

    task compare_state;
        begin
            sb.check32("PC",PC_out,model.expected_pc,cycle,model.last_pc,model.last_instr);
            sb.check32("saved NZCV",{28'b0,N_out,Z_out,C_out,V_out},
                       {28'b0,model.expected_flags},cycle,model.last_pc,model.last_instr);
            for (r=0;r<15;r=r+1) begin
                $sformat(label_text,"R%0d",r);
                sb.check32(label_text,dut.datapath_inst.rf.rf[r],
                           model.expected_regs[r],cycle,model.last_pc,model.last_instr);
            end
            // Compare the entire RAM, including unchanged locations: catches stray writes.
            for (m=0;m<256;m=m+1) begin
                $sformat(label_text,"RAM byte address %0d",4*m);
                sb.check32(label_text,dut.datapath_inst.dmem.ram[m],
                           model.expected_mem[m],cycle,model.last_pc,model.last_instr);
            end
        end
    endtask

    // Independently hand-calculated anchors also validate the test/model itself.
    task check_directed_results;
        reg [31:0] anchor;
        begin
            for (r=0;r<15;r=r+1) begin
                case (r)
                    2: anchor=32'h000000A4; // ADD R2,R15,#0 at byte PC 0x9C
                    3,4: anchor=32'h00000100;
                    6: anchor=32'h00000400;
                    8: anchor=7;
                    9,11: anchor=32'hFFFFFFFF;
                    13,14: anchor=32'h80000000;
                    default: anchor=0;
                endcase
                $sformat(label_text,"directed final R%0d",r);
                sb.check32(label_text,dut.datapath_inst.rf.rf[r],anchor,
                           cycle,model.last_pc,model.last_instr);
            end
            sb.check32("directed final NZCV",{28'b0,N_out,Z_out,C_out,V_out},
                       32'h6,cycle,model.last_pc,model.last_instr);
            sb.check32("directed RAM[0] overwrite",dut.datapath_inst.dmem.ram[0],90,
                       cycle,model.last_pc,model.last_instr);
            sb.check32("directed RAM[4] zero",dut.datapath_inst.dmem.ram[1],0,
                       cycle,model.last_pc,model.last_instr);
            sb.check32("directed RAM[12]",dut.datapath_inst.dmem.ram[3],256,
                       cycle,model.last_pc,model.last_instr);
            sb.check32("directed RAM[1020]",dut.datapath_inst.dmem.ram[255],25,
                       cycle,model.last_pc,model.last_instr);
        end
    endtask

    task collect_coverage;
        begin
            if (model.executed && model.kind>=0 && model.kind<=6)
                coverage_count[model.kind]=coverage_count[model.kind]+1;
            if (model.is_beq) begin
                if (model.executed) beq_taken=beq_taken+1;
                else beq_not_taken=beq_not_taken+1;
            end
            if (!model.executed && model.kind==5) skipped_store=skipped_store+1;
            if (!model.executed && model.kind<=3) skipped_register=skipped_register+1;
            if (model.executed) begin
                if (model.kind==4 && !model.memory_valid) invalid_load=invalid_load+1;
                if (model.kind==5 && !model.memory_valid) invalid_store=invalid_store+1;
                if (model.last_instr[20] && model.kind<=3) begin
                    if (model.kind==0 && model.expected_flags[1]) carry_add=carry_add+1;
                    if (model.kind==0 && model.expected_flags[0]) overflow_add=overflow_add+1;
                    if (model.kind==1 && model.expected_flags[0]) overflow_sub=overflow_sub+1;
                    if (model.kind==1 && model.expected_flags[2]) sub_equal=sub_equal+1;
                    if ((model.kind==2 || model.kind==3) && model.expected_flags[0])
                        logic_preserve_v=logic_preserve_v+1;
                end
                if (model.kind==2 || model.kind==3) begin
                    if (model.expected_result==0) logic_zero=logic_zero+1;
                    if (model.expected_result==32'hFFFFFFFF) logic_ones=logic_ones+1;
                end
            end
        end
    endtask

    task coverage_row;
        input [1023:0] name_text;
        input integer hits;
        begin
            $display("COVERAGE %0s = %0d",name_text,hits);
            $fdisplay(report_file,"%0s,%0d",name_text,hits);
            if (hits==0) $fatal(1,"Missing required coverage: %0s",name_text);
        end
    endtask

    initial begin
        if ($test$plusargs("DUMP_VCD")) begin
            $dumpfile("reference_wave.vcd");
            $dumpvars(0,tb_reference);
        end
        model.initialize("tests/reference/program.dat");
        sb.open_trace;
        for (k=0;k<7;k=k+1) coverage_count[k]=0;
        cycle=0;
        // Run twice; the second reset must preserve all RAM contents.
        for (epoch=1;epoch<=2;epoch=epoch+1) begin
            @(negedge clk);
            reset=1;
            model.reset_state;
            repeat (2) @(posedge clk);
            #1;
            compare_state;
            sb.check32("RegWrite during reset",{31'b0,RegWrite_out},0,cycle,0,0);
            sb.check32("MemWrite during reset",{31'b0,MemWrite_out},0,cycle,0,0);
            @(negedge clk);
            reset=0;
            completed=0;
            begin : execute_program
                for (k=0;k<160;k=k+1) begin
                    #1; // Combinational datapath settles before the commit edge.
                    model.step;
                    sb.check32("instruction PC",PC_out,model.last_pc,cycle,model.last_pc,model.last_instr);
                    sb.check32("instruction word",Instr_out,model.last_instr,cycle,model.last_pc,model.last_instr);
                    sb.check32("InstrValid",{31'b0,InstrValid_out},1,cycle,model.last_pc,model.last_instr);
                    sb.check32("RegWrite",{31'b0,RegWrite_out},{31'b0,model.expected_regwrite},cycle,model.last_pc,model.last_instr);
                    sb.check32("MemWrite",{31'b0,MemWrite_out},{31'b0,model.expected_memwrite},cycle,model.last_pc,model.last_instr);
                    sb.check32("PCSrc",{31'b0,PCSrc_out},{31'b0,model.expected_pcsrc},cycle,model.last_pc,model.last_instr);
                    if (model.executed && (model.kind==4 || model.kind==5)) begin
                        sb.check32("memory address",ALUResult_out,model.expected_address,cycle,model.last_pc,model.last_instr);
                        if (model.kind==5)
                            sb.check32("store data",WriteData_out,model.expected_store_data,cycle,model.last_pc,model.last_instr);
                        else begin
                            sb.check32("load data",ReadData_out,model.expected_load_data,cycle,model.last_pc,model.last_instr);
                            sb.check32("MemtoReg for LDR",{31'b0,MemtoReg_out},1,cycle,model.last_pc,model.last_instr);
                        end
                    end
                    collect_coverage;
                    @(posedge clk);
                    #1; // Wait until DUT nonblocking assignments have committed.
                    compare_state;
                    sb.trace_cycle(epoch,cycle,model.last_pc,model.last_instr,
                                   model.expected_pc,model.expected_flags);
                    cycle=cycle+1;
                    if (model.is_terminal) begin
                        completed=1;
                        disable execute_program;
                    end
                    @(negedge clk);
                end
            end
            if (!completed) $fatal(1,"Timeout: program did not reach terminal branch");
            check_directed_results;
            $display("EPOCH %0d PASSED",epoch);
        end
        report_file=$fopen("reference_coverage.csv","w");
        if (!report_file) $fatal(1,"Cannot open reference_coverage.csv");
        $fdisplay(report_file,"scenario,hits");
        coverage_row("ADD",coverage_count[0]);
        coverage_row("SUB",coverage_count[1]);
        coverage_row("AND",coverage_count[2]);
        coverage_row("ORR",coverage_count[3]);
        coverage_row("LDR",coverage_count[4]);
        coverage_row("STR",coverage_count[5]);
        coverage_row("BEQ taken",beq_taken);
        coverage_row("BEQ not taken",beq_not_taken);
        coverage_row("conditional store skipped",skipped_store);
        coverage_row("conditional register skipped",skipped_register);
        coverage_row("invalid address load returns zero",invalid_load);
        coverage_row("invalid address store ignored",invalid_store);
        coverage_row("ADD carry",carry_add);
        coverage_row("ADD overflow",overflow_add);
        coverage_row("SUB overflow",overflow_sub);
        coverage_row("SUB equal",sub_equal);
        coverage_row("logic zero",logic_zero);
        coverage_row("logic all ones",logic_ones);
        coverage_row("logic preserves V",logic_preserve_v);
        $fclose(report_file);
        sb.close_trace;
        $display("ALL REFERENCE TESTS PASSED (%0d instructions, %0d checks)",cycle,sb.checks);
        $finish;
    end

    initial begin
        #20000;
        $fatal(1,"Global testbench timeout");
    end
endmodule
