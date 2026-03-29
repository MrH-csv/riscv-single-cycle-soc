// ============================================================================
// Module:      data_memory
// Description: Memoria de datos (RAM) para procesador RISC-V RV32I
//              Single-Cycle. Lectura combinacional (asincrona) y escritura
//              sincrona (flanco de subida). Acceso a nivel de palabra (32 bits).
//
// Port Map:
//   clk          — Reloj del sistema
//   i_mem_write  — Habilitacion de escritura (1 = escribir)
//   i_mem_read   — Habilitacion de lectura  (1 = leer)
//   i_addr[31:0] — Direccion de byte (se usa [31:2] para indexar palabras)
//   i_wdata[31:0]— Dato a escribir
//   o_rdata[31:0]— Dato leido
//
// Notas:
//   - Direccionamiento por byte, alineado a palabra (bits [1:0] ignorados).
//   - Lectura combinacional para compatibilidad single-cycle.
//   - Profundidad configurable via parametro DEPTH (default 256 palabras).
// ============================================================================

module data_memory #(
    parameter DEPTH = 256        // Numero de palabras de 32 bits
)(
    input  wire        clk,
    input  wire        i_mem_write,   // Write Enable
    input  wire        i_mem_read,    // Read Enable
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
