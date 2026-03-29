# ============================================================
# Questa Sim — script para simular data_memory_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/data_memory.v
vlog -work work ../../source/data_memory_tb.v

vsim -t 1ps -voptargs="+acc" work.data_memory_tb

add wave                    /data_memory_tb/clk
add wave                    /data_memory_tb/i_mem_write
add wave                    /data_memory_tb/i_mem_read
add wave -radix hexadecimal /data_memory_tb/i_addr
add wave -radix hexadecimal /data_memory_tb/i_wdata
add wave -radix hexadecimal /data_memory_tb/o_rdata

run -all
