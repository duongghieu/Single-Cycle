# Copy this script next to top.sv; copy tests/reference beside it.
# Interactive: do {D:/your/project/run_reference.do}
# Batch: vsim -c -do "do run_reference.do; quit -f"
onerror {abort all}
set project_dir [file dirname [file normalize [info script]]]
cd $project_dir
if {![file exists top.sv]} {error "Place run_reference.do beside the project's top.sv"}
catch {quit -sim}
if {![file exists reference_work]} {vlib reference_work}
vmap reference_work [file join $project_dir reference_work]
transcript file reference_modelsim.log
vlog -sv -timescale 1ns/1ps -work reference_work \
    mux.sv PC.sv Register_file.sv instruction_memory.sv \
    datamem.sv ALU.sv shifter.sv extend.sv \
    Controlunit/main_decoder.sv Controlunit/ALU_Decoder.sv \
    Controlunit/cound_check.sv Controlunit/Decoder.sv \
    Controlunit/Control_unit.sv datapath.sv top.sv \
    tests/reference/reference_model.sv tests/reference/scoreboard.sv \
    tests/reference/tb_reference.sv
vsim -wlf reference_wave.wlf -voptargs=+acc reference_work.tb_reference
onfinish stop
log -r sim:/tb_reference/*
if {![batch_mode]} {
    add wave sim:/tb_reference/clk sim:/tb_reference/reset
    add wave -radix hexadecimal sim:/tb_reference/PC_out sim:/tb_reference/Instr_out
    add wave -radix hexadecimal sim:/tb_reference/model/expected_pc
    add wave -radix hexadecimal sim:/tb_reference/model/last_instr
    add wave sim:/tb_reference/RegWrite_out sim:/tb_reference/MemWrite_out sim:/tb_reference/PCSrc_out
    add wave sim:/tb_reference/N_out sim:/tb_reference/Z_out sim:/tb_reference/C_out sim:/tb_reference/V_out
    add wave -radix hexadecimal sim:/tb_reference/model/expected_flags
    add wave -radix hexadecimal sim:/tb_reference/dut/datapath_inst/rf/rf
    add wave -radix hexadecimal sim:/tb_reference/model/expected_regs
}
run -all
if {![batch_mode]} {wave zoom full}
