/***********************************************************
 * Descripcion:
 *   Unidad de comparacion para instrucciones de branch
 *   y jump del procesador RISC-V RV32I Single-Cycle.
 *   Evalua la condicion de salto segun funct3 y determina
 *   si el salto debe tomarse.
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

module branch_unit (
    input  wire [31:0] i_rs1_data,
    input  wire [31:0] i_rs2_data,
    input  wire [2:0]  i_funct3,
    input  wire        i_branch,
    input  wire        i_jump,
    output wire        o_pc_sel
);

    // ========================================================================
    // Evaluacion de condicion de branch
    // ========================================================================
    reg branch_taken;

    always @(*) begin
        branch_taken = 1'b0;
        case (i_funct3)
            3'b000:  branch_taken = (i_rs1_data == i_rs2_data);                        // BEQ
            3'b001:  branch_taken = (i_rs1_data != i_rs2_data);                        // BNE
            3'b100:  branch_taken = ($signed(i_rs1_data) < $signed(i_rs2_data));       // BLT
            3'b101:  branch_taken = ($signed(i_rs1_data) >= $signed(i_rs2_data));      // BGE
            3'b110:  branch_taken = (i_rs1_data < i_rs2_data);                         // BLTU
            3'b111:  branch_taken = (i_rs1_data >= i_rs2_data);                        // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    // ========================================================================
    // Seleccion de PC: salto incondicional (jump) o branch condicionado
    // ========================================================================
    assign o_pc_sel = i_jump | (i_branch & branch_taken);

endmodule
