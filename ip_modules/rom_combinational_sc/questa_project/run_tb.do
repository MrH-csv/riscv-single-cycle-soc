# ============================================================
# Questa Sim — script para simular rom_combinational_sc_tb
# Uso: En Questa, abrir este directorio y ejecutar:
#       do run_tb.do
# ============================================================

# Crear librería de trabajo
if {[file exists work]} {
    vdel -all -lib work
}
vlib work
vmap work work

# Compilar fuentes
vlog -work work ../../source/rom_combinational_sc.v
vlog -work work ../../source/rom_combinational_sc_tb.v

# Cargar simulación
vsim -t 1ps -voptargs="+acc" work.rom_combinational_sc_tb

# Agregar señales al Wave viewer
add wave -radix hexadecimal /rom_combinational_sc_tb/i_pc_addr
add wave -radix hexadecimal /rom_combinational_sc_tb/o_instruction

# Ejecutar
run -all