/***********************************************************
 * Descripcion:
 *   Banco de registros (x0-x31) para el procesador
 *   RISC-V Single-Cycle. 32 registros de WIDTH bits,
 *   2 puertos de lectura combinacional y 1 puerto de
 *   escritura sincrona. x0 hardwired a cero.
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

module register_file #(
    parameter WIDTH = 32
)(
    // Reloj
    input  wire                 clk,

    // Puerto de escritura (síncrono)
    input  wire                 i_we,       // Write Enable
    input  wire [4:0]           i_rd,       // Registro destino (rd)
    input  wire [WIDTH-1:0]     i_wdata,    // Dato a escribir

    // Puerto de lectura 1 (combinacional)
    input  wire [4:0]           i_rs1,      // Registro fuente 1 (rs1)
    output wire [WIDTH-1:0]     o_rdata1,   // Dato leído de rs1

    // Puerto de lectura 2 (combinacional)
    input  wire [4:0]           i_rs2,      // Registro fuente 2 (rs2)
    output wire [WIDTH-1:0]     o_rdata2    // Dato leído de rs2
);

    //=========================================================================
    // Arreglo de registros: x0 - x31
    // Nomenclatura RISC-V ISA (volumen I, capítulo 25 - tabla de registros):
    //   x0  (zero) - Hardwired zero
    //   x1  (ra)   - Return address
    //   x2  (sp)   - Stack pointer
    //   x3  (gp)   - Global pointer
    //   x4  (tp)   - Thread pointer
    //   x5  (t0)   - Temporary / alternate link register
    //   x6  (t1)   - Temporary
    //   x7  (t2)   - Temporary
    //   x8  (s0/fp)- Saved register / frame pointer
    //   x9  (s1)   - Saved register
    //   x10 (a0)   - Function argument / return value
    //   x11 (a1)   - Function argument / return value
    //   x12 (a2)   - Function argument
    //   x13 (a3)   - Function argument
    //   x14 (a4)   - Function argument
    //   x15 (a5)   - Function argument
    //   x16 (a6)   - Function argument
    //   x17 (a7)   - Function argument
    //   x18 (s2)   - Saved register
    //   x19 (s3)   - Saved register
    //   x20 (s4)   - Saved register
    //   x21 (s5)   - Saved register
    //   x22 (s6)   - Saved register
    //   x23 (s7)   - Saved register
    //   x24 (s8)   - Saved register
    //   x25 (s9)   - Saved register
    //   x26 (s10)  - Saved register
    //   x27 (s11)  - Saved register
    //   x28 (t3)   - Temporary
    //   x29 (t4)   - Temporary
    //   x30 (t5)   - Temporary
    //   x31 (t6)   - Temporary
    //=========================================================================
    reg [WIDTH-1:0] registers [0:31];

    //=========================================================================
    // Lectura combinacional (asíncrona)
    // Si la dirección es x0, retorna 0; de lo contrario, retorna el contenido.
    //=========================================================================
    assign o_rdata1 = (i_rs1 == 5'd0) ? {WIDTH{1'b0}} : registers[i_rs1];
    assign o_rdata2 = (i_rs2 == 5'd0) ? {WIDTH{1'b0}} : registers[i_rs2];

    //=========================================================================
    // Escritura síncrona (flanco de subida)
    // Solo escribe si i_we == 1 y el destino NO es x0 (zero).
    //=========================================================================
    always @(posedge clk) begin
        if (i_we && (i_rd != 5'd0)) begin
            registers[i_rd] <= i_wdata;
        end
    end

endmodule
