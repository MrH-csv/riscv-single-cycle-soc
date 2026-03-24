# ============================================================
# Questa Sim — script para simular adder_4_32b_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/adder_4_32b.v
vlog -work work ../../source/adder_4_32b_tb.v

vsim -t 1ps -voptargs="+acc" work.adder_4_32b_tb

add wave -radix hexadecimal /adder_4_32b_tb/i_a
add wave -radix hexadecimal /adder_4_32b_tb/i_b
add wave -radix hexadecimal /adder_4_32b_tb/o_sum

run -all