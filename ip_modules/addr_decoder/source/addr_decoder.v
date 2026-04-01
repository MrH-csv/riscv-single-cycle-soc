/***********************************************************
 * Descripcion:
 *   Decodificador de direcciones para el bus de datos
 *   del SoC. Genera senales chip-select segun los bits
 *   altos de la direccion y multiplexa el dato de lectura
 *   de vuelta al core.
 * Version:
 *   1.0
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
 *   29/03/2026
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

    // --- Datos de lectura de cada periferico ---
    input  wire [31:0] i_dmem_rdata,
    input  wire [31:0] i_gpio_rdata,

    // --- Dato de lectura multiplexado al core ---
    output reg  [31:0] o_rdata
);

    // ========================================================================
    // Decodificacion de direccion
    // ========================================================================

    wire is_gpio = (i_addr[31:16] == 16'h1001);
    wire is_dmem = ~is_gpio;

    assign o_cs_dmem = is_dmem & (i_mem_we | i_mem_re);
    assign o_cs_gpio = is_gpio & (i_mem_we | i_mem_re);

    // ========================================================================
    // MUX de lectura
    // ========================================================================

    always @(*) begin
        case (1'b1)
            is_gpio: o_rdata = i_gpio_rdata;
            default: o_rdata = i_dmem_rdata;
        endcase
    end

endmodule
