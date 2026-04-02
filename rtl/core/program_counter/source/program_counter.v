/***********************************************************
 * Descripcion:
 *   Registro D generico parametrizable utilizado como
 *   Program Counter (PC) para el procesador RISC-V.
 *   Cuenta con enable y reset sincrono.
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

module program_counter #(
    parameter WIDTH        = 32,              // Ancho del bus de datos
    parameter RESET_VECTOR = {WIDTH{1'b0}}    // Valor de salida tras reset
)(
    input  wire              clk,        // Senal de reloj del sistema
    input  wire              rst,        // Reset sincrono, activo en alto
    input  wire              en,         // Habilitacion de escritura, activo en alto
    input  wire [WIDTH-1:0]  i_next_pc,  // Siguiente valor del PC
    output reg  [WIDTH-1:0]  o_pc        // Valor actual del PC
);

    always @(posedge clk) begin
        if (rst)
            o_pc <= RESET_VECTOR;   // Reinicia el PC al vector de reset
        else if (en)
            o_pc <= i_next_pc;      // Captura el nuevo valor del PC
        // Si rst==0 y en==0, o_pc mantiene su valor (hold)
    end

endmodule
