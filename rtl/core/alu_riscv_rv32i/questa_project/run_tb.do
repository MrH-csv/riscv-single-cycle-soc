# ============================================================
# Questa Sim — script para simular alu_riscv_rv32i_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/alu_riscv_rv32i.v
vlog -work work ../../source/alu_riscv_rv32i_tb.v

vsim -t 1ps -voptargs="+acc" work.alu_riscv_rv32i_tb

add wave -radix hexadecimal /alu_riscv_rv32i_tb/i_a
add wave -radix hexadecimal /alu_riscv_rv32i_tb/i_b
add wave -radix binary      /alu_riscv_rv32i_tb/i_alu_ctrl
add wave -radix hexadecimal /alu_riscv_rv32i_tb/o_result
add wave                    /alu_riscv_rv32i_tb/o_zero

run -all
