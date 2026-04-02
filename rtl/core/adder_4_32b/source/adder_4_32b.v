/***********************************************************
 * Descripcion:
 *   Sumador parametrizable de WIDTH bits. Se utiliza
 *   para calcular PC+4 y PC+inmediato en el procesador
 *   RISC-V RV32I Single-Cycle.
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

module adder_4_32b #(
	parameter WIDTH = 32
)(
	input  [WIDTH-1:0] i_a,
	input  [WIDTH-1:0] i_b,
	output [WIDTH-1:0] o_sum
);

	assign o_sum = i_a + i_b;

endmodule
