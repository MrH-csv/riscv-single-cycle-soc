# ============================================================
# Questa Sim — script para simular main_control_rv32i_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/main_control_rv32i.v
vlog -work work ../../source/main_control_rv32i_tb.v

vsim -t 1ps -voptargs="+acc" work.main_control_rv32i_tb

add wave -radix binary      /main_control_rv32i_tb/i_opcode
add wave                    /main_control_rv32i_tb/o_branch
add wave                    /main_control_rv32i_tb/o_mem_read
add wave                    /main_control_rv32i_tb/o_memto_reg
add wave -radix binary      /main_control_rv32i_tb/o_alu_op
add wave                    /main_control_rv32i_tb/o_mem_write
add wave                    /main_control_rv32i_tb/o_alu_src
add wave                    /main_control_rv32i_tb/o_reg_write

run -all
