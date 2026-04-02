/***********************************************************
 * Descripcion:
 *   Decodificador de direcciones para el bus de datos
 *   del SoC. Genera senales chip-select segun los bits
 *   altos de la direccion y multiplexa el dato de lectura
 *   de vuelta al core.
 *
 *   Mapa de memoria:
 *     0x1001xx2x  -> GPIO  (offsets 0x24, 0x28)
 *     0x1001xx3x  -> UART  (offsets 0x30, 0x34, 0x38)
 *     Resto       -> DMEM  (RAM de datos)
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

module addr_decoder (
    // --- Bus del core ---
    input  wire [31:0] i_addr,
    input  wire        i_mem_we,
    input  wire        i_mem_re,

    // --- Chip selects ---
    output wire        o_cs_dmem,
    output wire        o_cs_gpio,
    output wire        o_cs_uart,

    // --- Datos de lectura de cada periferico ---
    input  wire [31:0] i_dmem_rdata,
    input  wire [31:0] i_gpio_rdata,
    input  wire [31:0] i_uart_rdata,

    // --- Dato de lectura multiplexado al core ---
    output reg  [31:0] o_rdata
);

    // ========================================================================
    // Decodificacion de direccion
    // ========================================================================

    wire is_periph = (i_addr[31:16] == 16'h1001);
    wire is_gpio   = is_periph & (i_addr[7:4] == 4'h2);
    wire is_uart   = is_periph & (i_addr[7:4] == 4'h3);
    wire is_dmem   = ~is_gpio & ~is_uart;

    assign o_cs_dmem = is_dmem & (i_mem_we | i_mem_re);
    assign o_cs_gpio = is_gpio & (i_mem_we | i_mem_re);
    assign o_cs_uart = is_uart & (i_mem_we | i_mem_re);

    // ========================================================================
    // MUX de lectura
    // ========================================================================

    always @(*) begin
        case (1'b1)
            is_uart: o_rdata = i_uart_rdata;
            is_gpio: o_rdata = i_gpio_rdata;
            default: o_rdata = i_dmem_rdata;
        endcase
    end

endmodule
