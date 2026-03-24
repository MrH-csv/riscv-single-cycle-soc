# ============================================================
# Questa Sim — script para simular imm_generator_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/imm_generator.v
vlog -work work ../../source/imm_generator_tb.v

vsim -t 1ps -voptargs="+acc" work.imm_generator_tb

add wave -radix hexadecimal /imm_generator_tb/i_instr
add wave -radix hexadecimal /imm_generator_tb/o_imm

run -all
