/***********************************************************
 * Descripcion:
 *   Multiplexor de 2 entradas y 1 salida, parametrizable
 *   en ancho de bits. Bloque combinacional generico para
 *   el datapath del procesador RISC-V.
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
module mux_2i_1o
#(
	parameter WIDTH = 32
)
(
	input  [WIDTH-1:0] i_d0,  // Dato de entrada 0
	input  [WIDTH-1:0] i_d1,  // Dato de entrada 1
	input              i_sel, // Selector: 0 -> i_d0, 1 -> i_d1
	output [WIDTH-1:0] o_out  // Dato de salida
);

	// Lógica combinacional: selección por operador ternario
	assign o_out = (i_sel) ? i_d1 : i_d0;

endmodule
