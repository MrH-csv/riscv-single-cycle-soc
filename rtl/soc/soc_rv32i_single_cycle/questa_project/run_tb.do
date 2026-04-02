# ============================================================
# Questa Sim — script para simular soc_rv32i_single_cycle_tb
# Uso: do run_tb.do
# ============================================================

if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

# --- Compilar core (rtl/core/) ---
vlog -work work ../../../core/adder_4_32b/source/adder_4_32b.v
vlog -work work ../../../core/alu_riscv_rv32i/source/alu_riscv_rv32i.v
vlog -work work ../../../core/control_alu_rv32i/source/control_alu_rv32i.v
vlog -work work ../../../core/imm_generator/source/imm_generator.v
vlog -work work ../../../core/main_control_rv32i/source/main_control_rv32i.v
vlog -work work ../../../core/mul_module/source/mul_module.v
vlog -work work ../../../core/mux_2i_1o/source/mux_2i_1o.v
vlog -work work ../../../core/mux_4i_1o/source/mux_4i_1o.v
vlog -work work ../../../core/program_counter/source/program_counter.v
vlog -work work ../../../core/register_file/source/register_file.v
vlog -work work ../../../core/branch_unit/source/branch_unit.v
vlog -work work ../../../core/rv32i_single_cycle/source/rv32i_single_cycle.v

# --- Compilar memory (rtl/memory/) ---
vlog -work work ../../../memory/rom_combinational_sc/source/rom_combinational_sc.v
vlog -work work ../../../memory/data_memory/source/data_memory.v

# --- Compilar peripherals (rtl/peripherals/) ---
vlog -work work ../../../peripherals/addr_decoder/source/addr_decoder.v
vlog -work work ../../../peripherals/gpio_peripheral/source/gpio_peripheral.v
vlog -work work ../../../peripherals/uart_tx/source/uart_tx.v
vlog -work work ../../../peripherals/uart_rx/source/uart_rx.v
vlog -work work ../../../peripherals/uart_peripheral/source/uart_peripheral.v

# --- Compilar SoC top-level y testbench ---
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
add wave                    /soc_rv32i_single_cycle_tb/dut/cs_uart
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/ram_rdata
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/gpio_rdata
add wave -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/uart_rdata
add wave                    /soc_rv32i_single_cycle_tb/dut/o_uart_tx
add wave                    /soc_rv32i_single_cycle_tb/dut/i_uart_rx

run -all
