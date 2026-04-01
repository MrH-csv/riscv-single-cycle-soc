/***********************************************************
 * Descripcion:
 *   Unidad Aritmetico-Logica (ALU) para el procesador
 *   RISC-V RV32I Single-Cycle. Implementa todas las
 *   operaciones computacionales enteras definidas en
 *   el set de instrucciones base RV32I.
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

module alu_riscv_rv32i #(
    parameter WIDTH = 32    // Ancho del camino de datos (32 bits para RV32I)
)(
    // --- Entradas de datos ---
    input  wire [WIDTH-1:0]  i_a,           // Operando A (tipicamente rs1 o PC)
    input  wire [WIDTH-1:0]  i_b,           // Operando B (tipicamente rs2 o inmediato)

    // --- Entrada de control ---
    input  wire [3:0]        i_alu_ctrl,    // Selector de operacion desde la unidad de control ALU

    // --- Salidas ---
    output reg  [WIDTH-1:0]  o_result,      // Resultado de la ALU
    output wire              o_zero         // Bandera de cero: 1 si o_result == 0
);

    // ========================================================================
    // Generacion de la bandera de cero
    // ------------------------------------------------------------------------
    // Asignacion continua: o_zero es ALTO cuando el resultado es exactamente
    // cero. Utilizado por la logica de salto para BEQ (o_zero == 1) y
    // BNE (o_zero == 0).
    // ========================================================================
    assign o_zero = (o_result == {WIDTH{1'b0}});

    // ========================================================================
    // Multiplexor de operaciones de la ALU - Puramente combinacional
    // ------------------------------------------------------------------------
    // Selecciona la operacion segun la senal de control de 4 bits i_alu_ctrl.
    // El bloque always @(*) asegura que no se infieran latches, ya que todos
    // los caminos (incluyendo default) asignan un valor a o_result.
    //
    // Nota sobre corrimientos: Solo los 5 bits bajos de i_b (i_b[4:0]) se
    // usan como cantidad de corrimiento, segun la especificacion RV32I
    // (shamt es de 5 bits para un camino de datos de 32 bits).
    //
    // Nota sobre SRA: $signed(i_a) es necesario para que el operador >>>
    // realice un corrimiento aritmetico (con extension de signo) en lugar
    // de un corrimiento logico.
    // ========================================================================
    always @(*) begin
        case (i_alu_ctrl)
            // --- Operaciones logicas ---
            4'b0000: o_result = i_a & i_b;             // AND: AND bit a bit (AND, ANDI)
            4'b0001: o_result = i_a | i_b;             // OR:  OR bit a bit  (OR, ORI)
            4'b0100: o_result = i_a ^ i_b;             // XOR: XOR bit a bit (XOR, XORI)

            // --- Operaciones aritmeticas ---
            4'b0010: o_result = i_a + i_b;             // ADD: Suma (ADD, ADDI, dir. Load/Store, AUIPC, JAL/JALR)
            4'b0110: o_result = i_a - i_b;             // SUB: Resta (SUB, comparacion BEQ/BNE)

            // --- Operaciones de corrimiento (shamt = i_b[4:0], 5 bits segun spec RV32I) ---
            4'b0101: o_result = i_a >> i_b[4:0];       // SRL: Corrimiento derecha logico  (SRL, SRLI)  - rellena con 0s
            4'b0111: o_result = i_a << i_b[4:0];       // SLL: Corrimiento izquierda logico (SLL, SLLI) - rellena con 0s
            4'b1000: o_result = $signed(i_a) >>> i_b[4:0]; // SRA: Corrimiento derecha aritmetico (SRA, SRAI) - preserva signo

            // --- Operaciones de comparacion (resultado es 1 o 0) ---
            4'b1001: o_result = ($signed(i_a) < $signed(i_b))   // SLT:  Menor que con signo   (SLT, SLTI)
                                ? {{WIDTH-1{1'b0}}, 1'b1}       //       Resultado = 1 si a < b (con signo)
                                : {WIDTH{1'b0}};                //       Resultado = 0 en caso contrario

            4'b1010: o_result = (i_a < i_b)                     // SLTU: Menor que sin signo  (SLTU, SLTIU)
                                ? {{WIDTH-1{1'b0}}, 1'b1}       //       Resultado = 1 si a < b (sin signo)
                                : {WIDTH{1'b0}};                //       Resultado = 0 en caso contrario

            // --- Default: evita inferencia de latches ---
            default: o_result = {WIDTH{1'b0}};          // Codigos de control no definidos retornan cero
        endcase
    end

endmodule
