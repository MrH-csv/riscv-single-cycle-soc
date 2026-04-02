onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /soc_rv32i_single_cycle_tb/dut/clk
add wave -noupdate /soc_rv32i_single_cycle_tb/dut/rst
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/o_gpio_out
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/i_gpio_in
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/imem_addr
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/imem_rdata
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/dmem_addr
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/dmem_wdata
add wave -noupdate /soc_rv32i_single_cycle_tb/dut/dmem_we
add wave -noupdate /soc_rv32i_single_cycle_tb/dut/dmem_re
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/dmem_rdata
add wave -noupdate /soc_rv32i_single_cycle_tb/dut/cs_dmem
add wave -noupdate /soc_rv32i_single_cycle_tb/dut/cs_gpio
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/ram_rdata
add wave -noupdate -radix hexadecimal /soc_rv32i_single_cycle_tb/dut/gpio_rdata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 104
configure wave -valuecolwidth 46
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {145704 ps}
