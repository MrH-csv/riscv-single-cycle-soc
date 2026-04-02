# ============================================================
# Questa Sim — script para simular mul_module_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/mul_module.v
vlog -work work ../../source/mul_module_tb.v

vsim -t 1ps -voptargs="+acc" work.mul_module_tb

add wave -radix hexadecimal /mul_module_tb/i_a
add wave -radix hexadecimal /mul_module_tb/i_b
add wave -radix hexadecimal /mul_module_tb/o_result

run -all
