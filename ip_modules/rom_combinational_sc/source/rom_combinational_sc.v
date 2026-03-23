// ============================================================
// Instruction ROM — RISC-V Single-Cycle Processor
//
// Port map
//   i_pc_addr     [31:0] — byte address from the PC
//   o_instruction [31:0] — 32-bit instruction word
//
// Reprogrammable: change the .hex file and re-synthesize
// without modifying the RTL.
// ============================================================

`timescale 1ns/1ps

module rom_combinational_sc #(
    parameter DEPTH    = 64,
    parameter HEX_FILE = "program.hex"
)(
    input  wire [31:0] i_pc_addr,
    output wire [31:0] o_instruction
);

    reg [31:0] rom_array [0:DEPTH-1];

    initial begin
        $readmemh(HEX_FILE, rom_array);
    end

    assign o_instruction = rom_array[i_pc_addr[31:2]];

endmodule