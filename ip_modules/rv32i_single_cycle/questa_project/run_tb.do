# ============================================================
# Questa Sim — script para simular rv32i_single_cycle_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

# --- Compilar todos los modulos IP ---
vlog -work work ../../../adder_4_32b/source/adder_4_32b.v
vlog -work work ../../../alu_riscv_rv32i/source/alu_riscv_rv32i.v
vlog -work work ../../../control_alu_rv32i/source/control_alu_rv32i.v
vlog -work work ../../../imm_generator/source/imm_generator.v
vlog -work work ../../../main_control_rv32i/source/main_control_rv32i.v
vlog -work work ../../../mul_module/source/mul_module.v
vlog -work work ../../../mux_2i_1o/source/mux_2i_1o.v
vlog -work work ../../../mux_4i_1o/source/mux_4i_1o.v
vlog -work work ../../../program_counter/source/program_counter.v
vlog -work work ../../../register_file/source/register_file.v
vlog -work work ../../../rom_combinational_sc/source/rom_combinational_sc.v

# --- Compilar modulos nuevos ---
vlog -work work ../../../data_memory/source/data_memory.v
vlog -work work ../../../branch_unit/source/branch_unit.v

# --- Compilar top-level y testbench ---
vlog -work work ../../source/rv32i_single_cycle.v
vlog -work work ../../source/rv32i_single_cycle_tb.v

vsim -t 1ps -voptargs="+acc" work.rv32i_single_cycle_tb

# --- Senales de Instruction Fetch ---
add wave -divider "INSTRUCTION FETCH"
add wave                    /rv32i_single_cycle_tb/clk
add wave                    /rv32i_single_cycle_tb/rst
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/pc_current
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/pc_plus_4
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/instruction

# --- Senales de Control ---
add wave -divider "CONTROL"
add wave -radix binary      /rv32i_single_cycle_tb/dut/opcode
add wave                    /rv32i_single_cycle_tb/dut/ctrl_reg_write
add wave -radix binary      /rv32i_single_cycle_tb/dut/ctrl_result_src
add wave                    /rv32i_single_cycle_tb/dut/ctrl_mem_write
add wave                    /rv32i_single_cycle_tb/dut/ctrl_mem_read
add wave                    /rv32i_single_cycle_tb/dut/ctrl_branch
add wave                    /rv32i_single_cycle_tb/dut/ctrl_jump
add wave                    /rv32i_single_cycle_tb/dut/ctrl_jalr
add wave -radix binary      /rv32i_single_cycle_tb/dut/ctrl_alu_op
add wave                    /rv32i_single_cycle_tb/dut/ctrl_alu_src
add wave                    /rv32i_single_cycle_tb/dut/ctrl_alu_a_src

# --- Senales de Ejecucion ---
add wave -divider "EXECUTE"
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/rs1_data
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/rs2_data
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/immediate
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/alu_input_a
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/alu_input_b
add wave -radix binary      /rv32i_single_cycle_tb/dut/alu_ctrl
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/alu_result
add wave                    /rv32i_single_cycle_tb/dut/alu_zero

# --- Senales de Memoria ---
add wave -divider "MEMORY"
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/mem_rdata

# --- Senales de Write-Back ---
add wave -divider "WRITE-BACK"
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/wb_data
add wave -radix unsigned    /rv32i_single_cycle_tb/dut/rd

# --- Senales de Branch/Jump ---
add wave -divider "BRANCH/JUMP"
add wave                    /rv32i_single_cycle_tb/dut/pc_sel
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/pc_target
add wave -radix hexadecimal /rv32i_single_cycle_tb/dut/pc_next

run -all
