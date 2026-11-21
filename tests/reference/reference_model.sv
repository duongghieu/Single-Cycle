`timescale 1ns/1ps
// Simulation-only architectural model. No DUT signals or modules are used here.
// Scope: the project's ARM A32 subset, not a complete ARM processor model.
module reference_model;
    reg [31:0] expected_pc;
    reg [31:0] expected_regs [0:14];
    reg [31:0] expected_mem [0:255];
    reg        mem_written [0:255];
    reg [31:0] program_mem [0:63];
    reg [3:0]  expected_flags; // NZCV

    // Intent for the instruction just processed, sampled BEFORE the DUT edge.
    reg [31:0] last_pc, last_instr, expected_address, expected_store_data;
    reg [31:0] expected_load_data, expected_result;
    reg expected_regwrite, expected_memwrite, expected_pcsrc;
    reg executed, is_beq, is_terminal, memory_valid;
    reg [3:0] destination;
    integer kind; // 0 ADD, 1 SUB, 2 AND, 3 ORR, 4 LDR, 5 STR, 6 B, 7 MOV, 8 EOR
    integer i;

    task initialize;
        input [2047:0] filename;
        begin
            for (i=0; i<64; i=i+1) program_mem[i] = 32'hEAFFFFFE;
            for (i=0; i<256; i=i+1) begin
                expected_mem[i] = 32'bx;
                mem_written[i] = 1'b0;
            end
            $readmemh(filename, program_mem);
            reset_state;
        end
    endtask

    task reset_state;
        begin
            expected_pc = 0;
            expected_flags = 0;
            for (i=0; i<15; i=i+1) expected_regs[i] = 0;
            // Data RAM deliberately survives reset, matching the project contract.
            expected_regwrite=0; expected_memwrite=0; expected_pcsrc=0;
            is_terminal=0;
        end
    endtask

    function [31:0] read_register;
        input [3:0] index;
        begin
            if (index==15) read_register=expected_pc+8;
            else read_register=expected_regs[index];
        end
    endfunction

    function condition_passes;
        input [3:0] condition;
        reg n,z,c,v;
        begin
            {n,z,c,v}=expected_flags;
            case (condition)
                0: condition_passes=z;
                1: condition_passes=!z;
                2: condition_passes=c;
                3: condition_passes=!c;
                4: condition_passes=n;
                5: condition_passes=!n;
                6: condition_passes=v;
                7: condition_passes=!v;
                8: condition_passes=c && !z;
                9: condition_passes=!c || z;
                10: condition_passes=(n==v);
                11: condition_passes=(n!=v);
                12: condition_passes=!z && (n==v);
                13: condition_passes=z || (n!=v);
                14: condition_passes=1;
                default: condition_passes=0;
            endcase
        end
    endfunction

    task step;
        reg [31:0] ins,a,b,value,result,next_pc,offset;
        reg [63:0] wide;
        reg carry,overflow,operand_carry,arithmetic,legal;
        reg [3:0] opcode;
        integer amount,rotate,index;
        begin
            last_pc=expected_pc;
            if (expected_pc[1:0]!=0 || expected_pc>=256)
                $fatal(1,"MODEL: instruction address outside test ROM: %h",expected_pc);
            ins=program_mem[expected_pc/4];
            last_instr=ins;
            if ((^ins)===1'bx) $fatal(1,"MODEL: unknown instruction at %h",expected_pc);
            executed=condition_passes(ins[31:28]);
            expected_regwrite=0; expected_memwrite=0; expected_pcsrc=0;
            expected_address=0; expected_store_data=0; expected_load_data=0;
            expected_result=0; memory_valid=0;
            destination=ins[15:12];
            is_beq=0; is_terminal=0; legal=1; kind=-1;
            next_pc=expected_pc+4;

            if (ins[31:28]==15) legal=0;
            case (ins[27:26])
                2'b00: begin
                    opcode=ins[24:21];
                    case (opcode)
                        4: kind=0;
                        2: kind=1;
                        0: kind=2;
                        12: kind=3;
                        13: kind=7;
                        1: kind=8;
                        default: legal=0;
                    endcase
                    if ((!ins[25] && ins[4]) ||
                        (opcode==13 && ins[19:16]!=0) ||
                        (ins[20] && destination==15)) legal=0;
                    a=read_register(ins[19:16]);
                    operand_carry=expected_flags[1];
                    if (ins[25]) begin
                        b={24'b0,ins[7:0]};
                        rotate=2*ins[11:8];
                        if (rotate!=0) begin
                            b=(b>>rotate)|(b<<(32-rotate));
                            operand_carry=b[31];
                        end
                    end else begin
                        value=read_register(ins[3:0]);
                        amount=ins[11:7];
                        b=value;
                        case (ins[6:5])
                            0: if (amount!=0) begin
                                b=value<<amount;
                                operand_carry=value[32-amount];
                            end
                            1: begin
                                if (amount==0) amount=32;
                                b=value>>amount;
                                operand_carry=value[amount-1];
                            end
                            2: begin
                                if (amount==0) amount=32;
                                b=$signed(value)>>>amount;
                                operand_carry=value[amount-1];
                            end
                            3: begin
                                if (amount==0) begin
                                    b={expected_flags[1],value[31:1]};
                                    operand_carry=value[0];
                                end else begin
                                    b=(value>>amount)|(value<<(32-amount));
                                    operand_carry=b[31];
                                end
                            end
                        endcase
                    end
                    arithmetic=0; carry=operand_carry; overflow=expected_flags[0];
                    result=0;
                    case (opcode)
                        4: begin
                            wide={32'b0,a}+{32'b0,b};
                            result=wide[31:0]; carry=(wide>64'hFFFFFFFF);
                            overflow=(a[31]==b[31]) && (result[31]!=a[31]);
                            arithmetic=1;
                        end
                        2: begin
                            result=a-b; carry=(a>=b);
                            overflow=(a[31]!=b[31]) && (result[31]!=a[31]);
                            arithmetic=1;
                        end
                        0: result=a&b;
                        12: result=a|b;
                        13: result=b;
                        1: result=a^b;
                        default: begin end
                    endcase
                    expected_result=result;
                    if (executed && legal) begin
                        expected_regwrite=1;
                        if (destination==15) begin
                            expected_pcsrc=1;
                            next_pc={result[31:2],2'b00};
                        end else expected_regs[destination]=result;
                        if (ins[20]) begin
                            expected_flags[3]=result[31];
                            expected_flags[2]=(result==0);
                            expected_flags[1]=carry;
                            if (arithmetic) expected_flags[0]=overflow;
                        end
                    end
                end
                2'b01: begin
                    // Only word, immediate positive offset, pre-index, no writeback.
                    if (ins[25:21]!=5'b01100) legal=0;
                    kind=ins[20] ? 4 : 5;
                    expected_address=read_register(ins[19:16])+{20'b0,ins[11:0]};
                    expected_store_data=read_register(destination);
                    memory_valid=(expected_address<1024 && expected_address[1:0]==0);
                    index=expected_address/4;
                    if (executed && legal) begin
                        if (ins[20]) begin
                            if (memory_valid) begin
                                if (!mem_written[index])
                                    $fatal(1,"MODEL: test reads unwritten RAM at %h",expected_address);
                                expected_load_data=expected_mem[index];
                            end else expected_load_data=0;
                            expected_result=expected_load_data;
                            expected_regwrite=1;
                            if (destination==15) begin
                                expected_pcsrc=1;
                                next_pc={expected_load_data[31:2],2'b00};
                            end else expected_regs[destination]=expected_load_data;
                        end else begin
                            // MemWrite intent remains 1 even when RAM rejects address.
                            expected_memwrite=1;
                            if (memory_valid) begin
                                expected_mem[index]=expected_store_data;
                                mem_written[index]=1;
                            end
                        end
                    end
                end
                2'b10: begin
                    if (ins[25:24]!=2'b10) legal=0; // B, not BL
                    kind=6;
                    is_beq=(ins[31:28]==0);
                    offset={{8{ins[23]}},ins[23:0]};
                    if (executed && legal) begin
                        next_pc=expected_pc+8+(offset<<2);
                        expected_pcsrc=1;
                        is_terminal=(next_pc==expected_pc);
                    end
                end
                default: legal=0;
            endcase
            // Never silently interpret an unsupported instruction as a passing NOP.
            if (!legal) $fatal(1,"MODEL: unsupported instruction %h at %h",ins,last_pc);
            expected_pc=next_pc;
        end
    endtask
endmodule
