/***********************************************************
 * Descripcion:
 *   Generador de inmediatos para el procesador RISC-V
 *   RV32I. Extrae y extiende en signo el campo inmediato
 *   segun el tipo de instruccion (I, S, B, U, J).
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

module imm_generator (
    input  wire [31:0] i_instr,
    output reg  [31:0] o_imm
);

    wire [6:0] opcode = i_instr[6:0];

    always @(*) begin
        case (opcode)
            // Tipo I: Loads, ADDI/ORI/etc., JALR
            7'b0000011,
            7'b0010011,
            7'b1100111: o_imm = {{21{i_instr[31]}}, i_instr[30:20]};

            // Tipo S: Stores
            7'b0100011:  o_imm = {{21{i_instr[31]}}, i_instr[30:25], i_instr[11:7]};

            // Tipo B: Branches
            7'b1100011:  o_imm = {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};

            // Tipo U: LUI, AUIPC
            7'b0110111,
            7'b0010111:  o_imm = {i_instr[31:12], 12'b0};

            // Tipo J: JAL
            7'b1101111:  o_imm = {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};

            default:     o_imm = 32'b0;
        endcase
    end

endmodule
