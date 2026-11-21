`timescale 1ns/1ps
module scoreboard;
    integer checks=0;
    integer trace_file;

    task open_trace;
        begin
            trace_file=$fopen("reference_trace.csv","w");
            if (!trace_file) $fatal(1,"Cannot open reference_trace.csv");
            $fdisplay(trace_file,"epoch,cycle,pc,instruction,next_pc,NZCV");
        end
    endtask

    task check32;
        input [1023:0] label_text;
        input [31:0] actual,expected;
        input integer cycle;
        input [31:0] pc,instruction;
        begin
            checks=checks+1;
            // Case inequality catches X/Z mismatches as well as numeric errors.
            if (actual !== expected)
                $fatal(1,"FAIL cycle=%0d PC=%08h instr=%08h %0s expected=%08h actual=%08h",
                       cycle,pc,instruction,label_text,expected,actual);
        end
    endtask

    task trace_cycle;
        input integer epoch,cycle;
        input [31:0] pc,instruction,next_pc;
        input [3:0] flags;
        begin
            $fdisplay(trace_file,"%0d,%0d,%08h,%08h,%08h,%01h",
                      epoch,cycle,pc,instruction,next_pc,flags);
        end
    endtask

    task close_trace;
        begin $fclose(trace_file); end
    endtask
endmodule
