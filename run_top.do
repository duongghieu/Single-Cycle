# ModelSim/Questa: do {D:/your/path/Single-Cycle/run_top.do}
# Sources and mem.dat are resolved relative to this script.
onerror {abort all}
set project_dir [file dirname [file normalize [info script]]]
cd $project_dir

if {![file exists tb_work]} {
    vlib tb_work
}
vmap tb_work [file join $project_dir tb_work]

vlog -sv -timescale 1ns/1ps -work tb_work \
    mux.sv PC.sv Register_file.sv instruction_memory.sv \
    datamem.sv ALU.sv shifter.sv extend.sv \
    Controlunit/main_decoder.sv Controlunit/ALU_Decoder.sv \
    Controlunit/cound_check.sv Controlunit/Decoder.sv \
    Controlunit/Control_unit.sv datapath.sv top.sv tb_top.sv

vsim -voptargs=+acc tb_work.tb_top
onfinish stop
add wave sim:/tb_top/clk sim:/tb_top/reset
add wave -radix hexadecimal \
    sim:/tb_top/PC_out sim:/tb_top/Instr_out \
    sim:/tb_top/SrcA_out sim:/tb_top/SrcB_out \
    sim:/tb_top/ALUResult_out sim:/tb_top/ALUControl_out
add wave sim:/tb_top/RegWrite_out sim:/tb_top/MemWrite_out \
    sim:/tb_top/PCSrc_out sim:/tb_top/InstrValid_out
add wave sim:/tb_top/N_out sim:/tb_top/Z_out \
    sim:/tb_top/C_out sim:/tb_top/V_out sim:/tb_top/ALUFlags_out
add wave -radix unsigned sim:/tb_top/dut/datapath_inst/rf/rf
run -all
wave zoom full
