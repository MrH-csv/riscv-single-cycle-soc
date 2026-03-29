// ============================================================
// Instruction ROM — RISC-V Single-Cycle Processor
//
// Implementacion puramente combinacional usando case statement.
// Quartus sintetiza esto en LUTs, no en bloques de RAM.
//
// Port map
//   i_pc_addr     [31:0] — byte address from the PC
//   o_instruction [31:0] — 32-bit instruction word
//
// Para cambiar el programa: editar las entradas del case.
// ============================================================

`timescale 1ns/1ps

module rom_combinational_sc #(
    parameter DEPTH    = 64,
    parameter HEX_FILE = "program.hex"
)(
    input  wire [31:0] i_pc_addr,
    output reg  [31:0] o_instruction
);

    wire [$clog2(DEPTH)-1:0] word_addr = i_pc_addr[$clog2(DEPTH)-1+2:2];

    // ================================================================
    // Programa: LED chaser controlado por switches (DE2-115)
    //
    // RESET_VECTOR = 0x0040_0000
    //
    //   auipc s0, 0xFC10          # s0 = PC + 0x0FC10000 = 0x10010000
    //   addi  s1, s0, 0x0024      # s1 = 0x10010024 (GPIO_OUT)
    //   addi  s2, s0, 0x0028      # s2 = 0x10010028 (GPIO_IN)
    //   lw    s5, 0(s2)           # s5 = valor switches (iteraciones)
    // LOOP_1:
    //   addi  s3, zero, 1         # s3 = 1 (LED inicial)
    //   addi  s4, zero, 8         # s4 = 8 (contador interno)
    // LOOP_2:
    //   sw    s3, 0(s1)           # gpio_out = s3 (enciende LED)
    //   slli  s3, s3, 1           # s3 <<= 1 (siguiente LED)
    //   addi  s4, s4, -1          # s4--
    //   bne   s4, zero, LOOP_2    # repetir 8 veces
    //   addi  s5, s5, -1          # s5--
    //   bne   s5, zero, LOOP_1    # repetir segun switches
    // EXIT:
    //   jal   zero, 0             # loop infinito
    // ================================================================

    always @(*) begin
        case (word_addr)
            6'd0:  o_instruction = 32'h0FC10417;  // auipc s0, 0xFC10
            6'd1:  o_instruction = 32'h02440493;  // addi  s1, s0, 0x0024
            6'd2:  o_instruction = 32'h02840913;  // addi  s2, s0, 0x0028
            6'd3:  o_instruction = 32'h00092A83;  // lw    s5, 0(s2)
            6'd4:  o_instruction = 32'h00100993;  // addi  s3, zero, 1
            6'd5:  o_instruction = 32'h00800A13;  // addi  s4, zero, 8
            6'd6:  o_instruction = 32'h0134A023;  // sw    s3, 0(s1)
            6'd7:  o_instruction = 32'h00199993;  // slli  s3, s3, 1
            6'd8:  o_instruction = 32'hFFFA0A13;  // addi  s4, s4, -1
            6'd9:  o_instruction = 32'hFE0A1AE3;  // bne   s4, zero, LOOP_2
            6'd10: o_instruction = 32'hFFFA8A93;  // addi  s5, s5, -1
            6'd11: o_instruction = 32'hFE0A92E3;  // bne   s5, zero, LOOP_1
            6'd12: o_instruction = 32'h0000006F;  // jal   zero, 0 (EXIT)
            default: o_instruction = 32'h00000013; // NOP
        endcase
    end

endmodule
