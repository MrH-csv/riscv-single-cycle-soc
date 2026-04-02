# ============================================================
# Questa Sim — script para simular register_file_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/register_file.v
vlog -work work ../../source/register_file_tb.v

vsim -t 1ps -voptargs="+acc" work.register_file_tb

add wave                    /register_file_tb/clk
add wave                    /register_file_tb/i_we
add wave -radix unsigned    /register_file_tb/i_rd
add wave -radix hexadecimal /register_file_tb/i_wdata
add wave -radix unsigned    /register_file_tb/i_rs1
add wave -radix hexadecimal /register_file_tb/o_rdata1
add wave -radix unsigned    /register_file_tb/i_rs2
add wave -radix hexadecimal /register_file_tb/o_rdata2

run -all
