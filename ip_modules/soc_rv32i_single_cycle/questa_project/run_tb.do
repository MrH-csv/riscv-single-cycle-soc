# ============================================================
# Questa Sim — script para simular soc_rv32i_single_cycle_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

# --- Compilar todos los modulos IP base ---
vlog -work work ../../adder_4_32b/source/adder_4_32b.v
vlog -work work ../../alu_riscv_rv32i/source/alu_riscv_rv32i.v
vlog -work work ../../control_alu_rv32i/source/control_alu_rv32i.v
vlog -work work ../../imm_generator/source/imm_generator.v
vlog -work work ../../main_control_rv32i/source/main_control_rv32i.v
vlog -work work ../../mul_module/source/mul_module.v
vlog -work work ../../mux_2i_1o/source/mux_2i_1o.v
vlog -work work ../../mux_4i_1o/source/mux_4i_1o.v
vlog -work work ../../program_counter/source/program_counter.v
vlog -work work ../../register_file/source/register_file.v
vlog -work work ../../rom_combinational_sc/source/rom_combinational_sc.v
vlog -work work ../../data_memory/source/data_memory.v
vlog -work work ../../branch_unit/source/branch_unit.v

# --- Compilar modulos nuevos del SoC ---
vlog -work work ../../addr_decoder/source/addr_decoder.v
vlog -work work ../../gpio_peripheral/source/gpio_peripheral.v

# --- Compilar core, top-level y testbench ---
vlog -work work ../../rv32i_single_cycle/source/rv32i_single_cycle.v
vlog -work work ../source/soc_rv32i_single_cycle.v
vlog -work work ../source/soc_rv32i_single_cycle_tb.v

# --- Copiar program.hex al directorio de trabajo ---
file copy -force ../source/program.hex ./program.hex

# --- Lanzar simulacion con visibilidad jerarquica ---
vsim -t 1ps -voptargs="+acc" -onfinish stop work.soc_rv32i_single_cycle_tb

# ============================================================
# Senales del waveform
# ============================================================

add wave                    /soc_rv32i_single_cycle_tb/dut/clk
add wave                    /soc_rv32i_single_cycle_tb/dut/rst
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/o_gpio_out
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/i_gpio_in
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/imem_addr
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/imem_rdata
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/dmem_addr
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/dmem_wdata
add wave                    /soc_rv32i_single_cycle_tb/dut/dmem_we
add wave                    /soc_rv32i_single_cycle_tb/dut/dmem_re
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/dmem_rdata
add wave                    /soc_rv32i_single_cycle_tb/dut/cs_dmem
add wave                    /soc_rv32i_single_cycle_tb/dut/cs_gpio
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/ram_rdata
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/gpio_rdata

run -all
