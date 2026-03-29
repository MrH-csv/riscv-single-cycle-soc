# ============================================================
# Questa Sim — script para simular branch_unit_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/branch_unit.v
vlog -work work ../../source/branch_unit_tb.v

vsim -t 1ps -voptargs="+acc" work.branch_unit_tb

add wave -radix hexadecimal /branch_unit_tb/i_rs1_data
add wave -radix hexadecimal /branch_unit_tb/i_rs2_data
add wave -radix binary      /branch_unit_tb/i_funct3
add wave                    /branch_unit_tb/i_branch
add wave                    /branch_unit_tb/i_jump
add wave                    /branch_unit_tb/o_pc_sel

run -all
