# ============================================================
# Questa Sim — script para simular program_counter_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/program_counter.v
vlog -work work ../../source/program_counter_tb.v

vsim -t 1ps -voptargs="+acc" work.program_counter_tb

add wave                    /program_counter_tb/clk
add wave                    /program_counter_tb/rst
add wave                    /program_counter_tb/en
add wave -radix hexadecimal /program_counter_tb/i_next_pc
add wave -radix hexadecimal /program_counter_tb/o_pc

run -all
