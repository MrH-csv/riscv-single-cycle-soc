/***********************************************************
 * Descripcion:
 *   Multiplexor de 4 entradas y 1 salida, parametrizable
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

module mux_4i_1o
#(
    parameter WIDTH = 32
)
(
    input  wire [WIDTH-1:0] i_d0,
    input  wire [WIDTH-1:0] i_d1,
    input  wire [WIDTH-1:0] i_d2,
    input  wire [WIDTH-1:0] i_d3,
    input  wire [1:0]       i_sel,
    output reg  [WIDTH-1:0] o_out
);

    // Logica combinacional del mux — sin inferencia de latches
    always @(*) begin
        case (i_sel)
            2'b00:   o_out = i_d0;
            2'b01:   o_out = i_d1;
            2'b10:   o_out = i_d2;
            2'b11:   o_out = i_d3;
            default: o_out = {WIDTH{1'b0}};
        endcase
    end

endmodule
