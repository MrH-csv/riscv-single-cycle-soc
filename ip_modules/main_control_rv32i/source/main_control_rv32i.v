// ============================================================================
// Module: main_control_rv32i
// Description: Unidad de Control Principal para un procesador RISC-V RV32I
//              Single-Cycle. Decodifica el opcode de la instruccion y genera
//              las senales de control para el datapath.
// ============================================================================

module main_control_rv32i (
    // --- Entrada ---
    input  wire [6:0] i_opcode,   // Bits [6:0] de la instruccion (opcode)

    // --- Salidas de control ---
    output reg        o_branch,    // Habilita comparacion de branch en el datapath
    output reg        o_mem_read,  // Habilita lectura de memoria de datos
    output reg        o_memto_reg, // Selecciona dato de memoria (1) o resultado ALU (0) hacia registro
    output reg  [1:0] o_alu_op,   // Codigo de operacion para la ALU Control Unit
    output reg        o_mem_write, // Habilita escritura en memoria de datos
    output reg        o_alu_src,   // Selecciona inmediato (1) o registro rs2 (0) como operando B de la ALU
    output reg        o_reg_write  // Habilita escritura en el banco de registros
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
        o_branch    = 1'b0;
        o_mem_read  = 1'b0;
        o_memto_reg = 1'b0;
        o_alu_op    = 2'b00;
        o_mem_write = 1'b0;
        o_alu_src   = 1'b0;
        o_reg_write = 1'b0;

        case (i_opcode)
            // ------------------------------------------------------------
            // Tipo R (add, sub, and, or, slt, etc.)
            // Opcode: 0110011
            // Operacion ALU entre dos registros, resultado escrito en rd.
            // ------------------------------------------------------------
            7'b0110011: begin
                o_reg_write = 1'b1;
                o_alu_op    = 2'b10;
            end

            // ------------------------------------------------------------
            // Tipo I - ALU (addi, andi, ori, slti, etc.)
            // Opcode: 0010011
            // Operacion ALU con inmediato como operando B.
            // ------------------------------------------------------------
            7'b0010011: begin
                o_alu_src   = 1'b1;
                o_reg_write = 1'b1;
                o_alu_op    = 2'b10;
            end

            // ------------------------------------------------------------
            // Tipo L - Load (lw, lh, lb, etc.)
            // Opcode: 0000011
            // Calcula direccion (base + offset), lee memoria y escribe
            // el dato leido en el registro destino.
            // ------------------------------------------------------------
            7'b0000011: begin
                o_alu_src   = 1'b1;
                o_memto_reg = 1'b1;
                o_reg_write = 1'b1;
                o_mem_read  = 1'b1;
                o_alu_op    = 2'b00;
            end

            // ------------------------------------------------------------
            // Tipo S - Store (sw, sh, sb, etc.)
            // Opcode: 0100011
            // Calcula direccion (base + offset) y escribe el contenido
            // de rs2 en memoria de datos.
            // ------------------------------------------------------------
            7'b0100011: begin
                o_alu_src   = 1'b1;
                o_mem_write = 1'b1;
                o_alu_op    = 2'b00;
            end

            // ------------------------------------------------------------
            // Tipo B - Branch (beq, bne, blt, bge, etc.)
            // Opcode: 1100011
            // Compara dos registros; el resultado de la ALU determina
            // si se toma el salto condicional.
            // ------------------------------------------------------------
            7'b1100011: begin
                o_branch = 1'b1;
                o_alu_op = 2'b01;
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
