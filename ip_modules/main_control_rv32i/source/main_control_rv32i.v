/***********************************************************
 * Descripcion:
 *   Unidad de Control Principal para el procesador
 *   RISC-V RV32I Single-Cycle. Decodifica el opcode
 *   de la instruccion y genera las senales de control
 *   para el datapath.
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

module main_control_rv32i (
    // --- Entrada ---
    input  wire [6:0] i_opcode,   // Bits [6:0] de la instruccion (opcode)

    // --- Salidas de control ---
    output reg        o_reg_write,   // Habilita escritura en el banco de registros
    output reg  [1:0] o_result_src,  // Fuente del write-back (00:ALU, 01:Mem, 10:PC+4, 11:Imm)
    output reg        o_mem_write,   // Habilita escritura en memoria de datos
    output reg        o_mem_read,    // Habilita lectura de memoria de datos
    output reg        o_branch,      // Habilita comparacion de branch en el datapath
    output reg        o_jump,        // Salto incondicional (JAL/JALR)
    output reg        o_jalr,        // JALR: target desde resultado de ALU
    output reg  [1:0] o_alu_op,      // Codigo de operacion para la ALU Control Unit
    output reg        o_alu_src,     // Selecciona inmediato (1) o registro rs2 (0) como operando B
    output reg        o_alu_a_src    // Selecciona PC (1) o registro rs1 (0) como operando A
);

    // ========================================================================
    // Logica combinacional de decodificacion
    // ========================================================================
    always @(*) begin
        // ----------------------------------------------------------------
        // Valores por defecto: todas las salidas en 0.
        // Esto garantiza que no se infieran latches y que cualquier
        // opcode no reconocido produzca un estado seguro (NOP efectivo).
        // ----------------------------------------------------------------
        o_reg_write  = 1'b0;
        o_result_src = 2'b00;
        o_mem_write  = 1'b0;
        o_mem_read   = 1'b0;
        o_branch     = 1'b0;
        o_jump       = 1'b0;
        o_jalr       = 1'b0;
        o_alu_op     = 2'b00;
        o_alu_src    = 1'b0;
        o_alu_a_src  = 1'b0;

        case (i_opcode)
            // ------------------------------------------------------------
            // Tipo R (add, sub, and, or, slt, sll, srl, sra, sltu, xor)
            // Opcode: 0110011
            // Operacion ALU entre dos registros, resultado escrito en rd.
            // ------------------------------------------------------------
            7'b0110011: begin
                o_reg_write = 1'b1;
                o_alu_op    = 2'b10;
            end

            // ------------------------------------------------------------
            // Tipo I - ALU (addi, andi, ori, slti, sltiu, xori, slli, srli, srai)
            // Opcode: 0010011
            // Operacion ALU con inmediato como operando B.
            // ------------------------------------------------------------
            7'b0010011: begin
                o_reg_write = 1'b1;
                o_alu_op    = 2'b10;
                o_alu_src   = 1'b1;
            end

            // ------------------------------------------------------------
            // Tipo L - Load (lw, lh, lb, lhu, lbu)
            // Opcode: 0000011
            // Calcula direccion (base + offset), lee memoria y escribe
            // el dato leido en el registro destino.
            // ------------------------------------------------------------
            7'b0000011: begin
                o_reg_write  = 1'b1;
                o_result_src = 2'b01;
                o_mem_read   = 1'b1;
                o_alu_src    = 1'b1;
            end

            // ------------------------------------------------------------
            // Tipo S - Store (sw, sh, sb)
            // Opcode: 0100011
            // Calcula direccion (base + offset) y escribe el contenido
            // de rs2 en memoria de datos.
            // ------------------------------------------------------------
            7'b0100011: begin
                o_mem_write = 1'b1;
                o_alu_src   = 1'b1;
            end

            // ------------------------------------------------------------
            // Tipo B - Branch (beq, bne, blt, bge, bltu, bgeu)
            // Opcode: 1100011
            // Compara dos registros; la branch_unit determina si se
            // toma el salto condicional.
            // ------------------------------------------------------------
            7'b1100011: begin
                o_branch = 1'b1;
                o_alu_op = 2'b01;
            end

            // ------------------------------------------------------------
            // Tipo U - LUI (Load Upper Immediate)
            // Opcode: 0110111
            // Carga el inmediato de 20 bits en los bits [31:12] de rd.
            // El write-back viene directamente del inmediato (result_src=11).
            // ------------------------------------------------------------
            7'b0110111: begin
                o_reg_write  = 1'b1;
                o_result_src = 2'b11;
            end

            // ------------------------------------------------------------
            // Tipo U - AUIPC (Add Upper Immediate to PC)
            // Opcode: 0010111
            // Suma PC + inmediato de 20 bits (shifted <<12).
            // ALU operando A = PC, operando B = inmediato.
            // ------------------------------------------------------------
            7'b0010111: begin
                o_reg_write = 1'b1;
                o_alu_src   = 1'b1;
                o_alu_a_src = 1'b1;
            end

            // ------------------------------------------------------------
            // Tipo J - JAL (Jump and Link)
            // Opcode: 1101111
            // Guarda PC+4 en rd y salta a PC + offset.
            // ------------------------------------------------------------
            7'b1101111: begin
                o_reg_write  = 1'b1;
                o_result_src = 2'b10;
                o_jump       = 1'b1;
            end

            // ------------------------------------------------------------
            // Tipo I - JALR (Jump and Link Register)
            // Opcode: 1100111
            // Guarda PC+4 en rd y salta a (rs1 + imm) con LSB = 0.
            // La ALU calcula rs1 + imm; el resultado es el target.
            // ------------------------------------------------------------
            7'b1100111: begin
                o_reg_write  = 1'b1;
                o_result_src = 2'b10;
                o_jump       = 1'b1;
                o_jalr       = 1'b1;
                o_alu_src    = 1'b1;
            end

            // ------------------------------------------------------------
            // Default: opcode no reconocido.
            // Todas las salidas permanecen en 0 (asignacion por defecto).
            // ------------------------------------------------------------
            default: begin
                // No-op: valores por defecto ya asignados
            end
        endcase
    end

endmodule
