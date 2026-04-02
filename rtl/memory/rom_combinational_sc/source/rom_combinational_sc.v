/***********************************************************
 * Descripcion:
 *   ROM de instrucciones combinacional para el procesador
 *   RISC-V Single-Cycle. Implementacion puramente
 *   combinacional usando case statement. Quartus
 *   sintetiza esto en LUTs.
 * Version:
 *   1.1
 * Autor:
 *   Angel Habid Navarro Mendez
 * Profesor:
 *   Dr. Jose Luis Pizano Escalante
 * Programa:
 *   Maestria en Diseno Electronico
 * Institucion:
 *   Instituto Tecnologico y de Estudios Superiores
 *   de Occidente
 * Fecha:
 *   02/04/2026
 ***********************************************************/

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
    // Programa: Factorial via UART
    //
    // RESET_VECTOR = 0x0040_0000
    //
    // Recibe un byte (n) por UART, calcula n!, y transmite
    // el resultado de 32 bits en 4 bytes (MSB primero).
    //
    // Mapa de registros UART (base 0x10010000):
    //   0x30  UART_TX_DATA  (W)  - dato a transmitir
    //   0x34  UART_RX_DATA  (R)  - dato recibido
    //   0x38  UART_STATUS   (R)  - bit0: tx_busy, bit1: rx_ready
    //
    // Registros utilizados:
    //   s0 = base perifericos (0x10010000)
    //   s1 = &UART_TX_DATA   (0x10010030)
    //   s2 = &UART_RX_DATA   (0x10010034)
    //   s3 = &UART_STATUS    (0x10010038)
    //   a0 = n (contador descendente)
    //   a1 = resultado (factorial)
    //   a2 = byte a transmitir
    //   t0 = temporal (lectura de status)
    // ================================================================

    always @(*) begin
        case (word_addr)
            // ==============================================================
            // Inicializacion de direcciones base
            // ==============================================================
            6'd0:  o_instruction = 32'h0FC10417;  // auipc s0, 0xFC10       -> s0 = 0x10010000
            6'd1:  o_instruction = 32'h03040493;  // addi  s1, s0, 0x030    -> s1 = UART_TX_DATA
            6'd2:  o_instruction = 32'h03440913;  // addi  s2, s0, 0x034    -> s2 = UART_RX_DATA
            6'd3:  o_instruction = 32'h03840993;  // addi  s3, s0, 0x038    -> s3 = UART_STATUS

            // ==============================================================
            // WAIT_RX: esperar hasta que rx_ready == 1
            // ==============================================================
            6'd4:  o_instruction = 32'h0009A283;  // lw    t0, 0(s3)
            6'd5:  o_instruction = 32'h0022F293;  // andi  t0, t0, 2        -> bit 1: rx_ready
            6'd6:  o_instruction = 32'hFE028CE3;  // beq   t0, zero, -8     -> WAIT_RX

            // ==============================================================
            // Leer dato recibido (n)
            // ==============================================================
            6'd7:  o_instruction = 32'h00092503;  // lw    a0, 0(s2)        -> a0 = n

            // ==============================================================
            // Calcular factorial(n)
            // ==============================================================
            6'd8:  o_instruction = 32'h00100593;  // addi  a1, zero, 1      -> a1 = 1
            6'd9:  o_instruction = 32'h00050863;  // beq   a0, zero, +16    -> SEND (si n==0)

            // FACT_LOOP:
            6'd10: o_instruction = 32'h02A585B3;  // mul   a1, a1, a0       -> a1 *= a0
            6'd11: o_instruction = 32'hFFF50513;  // addi  a0, a0, -1       -> a0--
            6'd12: o_instruction = 32'hFE051CE3;  // bne   a0, zero, -8     -> FACT_LOOP

            // ==============================================================
            // SEND: transmitir resultado (4 bytes, MSB primero)
            // ==============================================================

            // --- Byte 3 (MSB): bits [31:24] ---
            6'd13: o_instruction = 32'h0185D613;  // srli  a2, a1, 24

            // WAIT_TX_3:
            6'd14: o_instruction = 32'h0009A283;  // lw    t0, 0(s3)
            6'd15: o_instruction = 32'h0012F293;  // andi  t0, t0, 1        -> bit 0: tx_busy
            6'd16: o_instruction = 32'hFE029CE3;  // bne   t0, zero, -8     -> WAIT_TX_3
            6'd17: o_instruction = 32'h00C4A023;  // sw    a2, 0(s1)        -> transmitir

            // --- Byte 2: bits [23:16] ---
            6'd18: o_instruction = 32'h0105D613;  // srli  a2, a1, 16
            6'd19: o_instruction = 32'h0FF67613;  // andi  a2, a2, 0xFF

            // WAIT_TX_2:
            6'd20: o_instruction = 32'h0009A283;  // lw    t0, 0(s3)
            6'd21: o_instruction = 32'h0012F293;  // andi  t0, t0, 1
            6'd22: o_instruction = 32'hFE029CE3;  // bne   t0, zero, -8     -> WAIT_TX_2
            6'd23: o_instruction = 32'h00C4A023;  // sw    a2, 0(s1)

            // --- Byte 1: bits [15:8] ---
            6'd24: o_instruction = 32'h0085D613;  // srli  a2, a1, 8
            6'd25: o_instruction = 32'h0FF67613;  // andi  a2, a2, 0xFF

            // WAIT_TX_1:
            6'd26: o_instruction = 32'h0009A283;  // lw    t0, 0(s3)
            6'd27: o_instruction = 32'h0012F293;  // andi  t0, t0, 1
            6'd28: o_instruction = 32'hFE029CE3;  // bne   t0, zero, -8     -> WAIT_TX_1
            6'd29: o_instruction = 32'h00C4A023;  // sw    a2, 0(s1)

            // --- Byte 0 (LSB): bits [7:0] ---
            6'd30: o_instruction = 32'h0FF5F613;  // andi  a2, a1, 0xFF

            // WAIT_TX_0:
            6'd31: o_instruction = 32'h0009A283;  // lw    t0, 0(s3)
            6'd32: o_instruction = 32'h0012F293;  // andi  t0, t0, 1
            6'd33: o_instruction = 32'hFE029CE3;  // bne   t0, zero, -8     -> WAIT_TX_0
            6'd34: o_instruction = 32'h00C4A023;  // sw    a2, 0(s1)

            // ==============================================================
            // Volver a esperar siguiente entrada
            // ==============================================================
            6'd35: o_instruction = 32'hF85FF06F;  // jal   zero, -124       -> WAIT_RX

            default: o_instruction = 32'h00000013; // NOP (addi zero, zero, 0)
        endcase
    end

endmodule
