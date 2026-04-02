transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog  -work work +incdir+/home/habid/riscv-single-cycle-soc/rtl/memory/rom_combinational_sc/source {/home/habid/riscv-single-cycle-soc/rtl/memory/rom_combinational_sc/source/rom_combinational_sc.v}

