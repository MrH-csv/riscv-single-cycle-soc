/***********************************************************
 * Descripcion:
 *   Memoria de datos (RAM) para el procesador RISC-V
 *   RV32I Single-Cycle. Lectura combinacional (asincrona)
 *   y escritura sincrona (flanco de subida). Acceso a
 *   nivel de palabra (32 bits).
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

module data_memory #(
    parameter DEPTH = 256        // Numero de palabras de 32 bits
)(
    input  wire        clk,
    input  wire        i_mem_write,   // Habilitacion de escritura
    input  wire        i_mem_read,    // Habilitacion de lectura
    input  wire [31:0] i_addr,        // Direccion de byte
    input  wire [31:0] i_wdata,       // Dato a escribir
    output wire [31:0] o_rdata        // Dato leido
);

    // ========================================================================
    // Arreglo de memoria: DEPTH palabras de 32 bits
    // ========================================================================
    reg [31:0] mem_array [0:DEPTH-1];

    // ========================================================================
    // Indice de palabra: descartar los 2 bits menos significativos
    // ========================================================================
    wire [31:0] word_addr = i_addr[31:2];

    // ========================================================================
    // Lectura combinacional (asincrona)
    // Retorna 0 si i_mem_read esta deshabilitado.
    // ========================================================================
    assign o_rdata = (i_mem_read) ? mem_array[word_addr] : 32'b0;

    // ========================================================================
    // Escritura sincrona (flanco de subida)
    // ========================================================================
    always @(posedge clk) begin
        if (i_mem_write) begin
            mem_array[word_addr] <= i_wdata;
        end
    end

endmodule
