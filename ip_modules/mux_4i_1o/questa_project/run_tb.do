# ============================================================
# Questa Sim — script para simular mux_4i_1o_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/mux_4i_1o.v
vlog -work work ../../source/mux_4i_1o_tb.v

vsim -t 1ps -voptargs="+acc" work.mux_4i_1o_tb

add wave -radix hexadecimal /mux_4i_1o_tb/i_d0
add wave -radix hexadecimal /mux_4i_1o_tb/i_d1
add wave -radix hexadecimal /mux_4i_1o_tb/i_d2
add wave -radix hexadecimal /mux_4i_1o_tb/i_d3
add wave -radix binary      /mux_4i_1o_tb/i_sel
add wave -radix hexadecimal /mux_4i_1o_tb/o_out

run -all
