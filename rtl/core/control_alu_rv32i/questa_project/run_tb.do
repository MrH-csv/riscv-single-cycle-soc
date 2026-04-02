# ============================================================
# Questa Sim — script para simular control_alu_rv32i_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

vlog -work work ../../source/control_alu_rv32i.v
vlog -work work ../../source/control_alu_rv32i_tb.v

vsim -t 1ps -voptargs="+acc" work.control_alu_rv32i_tb

# ---- Senales de entrada (estimulos) ----
add wave -divider "ENTRADAS"
add wave -radix unsigned    /control_alu_rv32i_tb/test_num
add wave -radix binary      /control_alu_rv32i_tb/i_alu_op
add wave -radix binary      /control_alu_rv32i_tb/i_funct3
add wave                    /control_alu_rv32i_tb/i_funct7_5
add wave                    /control_alu_rv32i_tb/i_funct7_0
add wave                    /control_alu_rv32i_tb/i_op5

# ---- Salidas del DUT ----
add wave -divider "SALIDAS DUT"
add wave -radix binary      /control_alu_rv32i_tb/o_alu_ctrl
add wave                    /control_alu_rv32i_tb/o_mul_sel

# ---- Verificacion (valores esperados vs reales) ----
add wave -divider "VERIFICACION"
add wave -radix binary      /control_alu_rv32i_tb/exp_alu_ctrl
add wave -radix binary      /control_alu_rv32i_tb/exp_mul_sel
add wave -color green       /control_alu_rv32i_tb/ctrl_match
add wave -color green       /control_alu_rv32i_tb/mul_match
add wave -color {lime green} /control_alu_rv32i_tb/test_pass

run -all

# Ajustar zoom para ver todos los tests
wave zoom full
