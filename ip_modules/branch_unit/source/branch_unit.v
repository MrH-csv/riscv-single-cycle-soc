// ============================================================================
// Module:      branch_unit
// Description: Unidad de comparacion para instrucciones de branch y jump
//              del procesador RISC-V RV32I Single-Cycle.
//
//              Evalua la condicion de branch segun funct3 y determina si
//              el salto debe tomarse. Tambien maneja saltos incondicionales
//              (JAL/JALR).
//
// Port Map:
//   i_rs1_data [31:0] — Dato del registro fuente 1
//   i_rs2_data [31:0] — Dato del registro fuente 2
//   i_funct3   [2:0]  — Campo funct3 de la instruccion (tipo de branch)
//   i_branch          — Senal de branch desde Main Control
//   i_jump            — Senal de jump desde Main Control (JAL/JALR)
//   o_pc_sel          — 1: tomar salto (branch/jump), 0: PC+4
//
// Codificacion funct3 para branches (RV32I):
//   3'b000 -> BEQ  (Branch if Equal)
//   3'b001 -> BNE  (Branch if Not Equal)
//   3'b100 -> BLT  (Branch if Less Than, signed)
//   3'b101 -> BGE  (Branch if Greater or Equal, signed)
//   3'b110 -> BLTU (Branch if Less Than, unsigned)
//   3'b111 -> BGEU (Branch if Greater or Equal, unsigned)
// ============================================================================

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
