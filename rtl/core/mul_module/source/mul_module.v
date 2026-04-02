/***********************************************************
 * Descripcion:
 *   Multiplicador por hardware para la instruccion MUL
 *   de RV32M. Retorna los WIDTH bits inferiores del
 *   producto completo (a * b). Logica puramente
 *   combinacional.
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

module mul_module #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] i_a,      // Multiplicando (rs1)
    input  wire [WIDTH-1:0] i_b,      // Multiplicador (rs2)
    output wire [WIDTH-1:0] o_result  // WIDTH bits inferiores de (i_a * i_b)
);

    // Producto completo — la herramienta de sintesis detecta una
    // multiplicacion de WIDTH x WIDTH y la mapea en bloque(s) DSP.
    // Solo se enruta la mitad inferior, lo cual es correcto para MUL
    // (el signo es irrelevante para los bits inferiores).
    wire [2*WIDTH-1:0] product;

    assign product  = i_a * i_b;
    assign o_result = product[WIDTH-1:0];

endmodule
