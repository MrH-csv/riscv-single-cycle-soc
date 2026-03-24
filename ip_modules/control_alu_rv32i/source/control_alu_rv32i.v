/******************************************************************************
 * Module:  alu_control_rv32im
 *
 * Decodificador de Control de la ALU para procesador RISC-V Single-Cycle.
 * Soporta instrucciones base RV32I y MUL de la extension RV32M.
 *
 * Logica estrictamente combinacional.
 *
 * Nota: Se usa i_op5 (bit 5 del opcode) para diferenciar Tipo R (opcode
 *       0110011, i_op5=1) de Tipo I (opcode 0010011, i_op5=0). Esto evita
 *       el clasico "bug del ADDI", donde el bit 30 de un inmediato se
 *       confundiria con funct7[5] y causaria una resta en vez de suma.
 *
 * Codificacion de o_alu_ctrl:
 *   4'b0000 -> AND
 *   4'b0001 -> OR
 *   4'b0010 -> ADD
 *   4'b0100 -> XOR
 *   4'b0101 -> SRL
 *   4'b0110 -> SUB
 *   4'b0111 -> SLL
 *   4'b1000 -> SRA
 *   4'b1001 -> SLT
 *   4'b1010 -> SLTU
 *****************************************************************************/

module control_alu_rv32i (
    input  wire [1:0] i_alu_op,     // Senal de la Unidad de Control Principal
    input  wire [2:0] i_funct3,     // Bits [14:12] de la instruccion
    input  wire       i_funct7_5,   // Bit 30 de la instruccion
    input  wire       i_funct7_0,   // Bit 25 de la instruccion
    input  wire       i_op5,        // Bit 5 del opcode (1=Tipo R, 0=Tipo I)

    output reg  [3:0] o_alu_ctrl,   // Senal de control hacia la ALU
    output reg        o_mul_sel     // 1 si la instruccion es MUL
);

    always @(*) begin
        // Valores por defecto para evitar latches
        o_alu_ctrl = 4'b0000;
        o_mul_sel  = 1'b0;

        case (i_alu_op)
            // ---------------------------------------------------------------
            // Load / Store: la ALU calcula base + offset (ADD)
            // ---------------------------------------------------------------
            2'b00: o_alu_ctrl = 4'b0010;

            // ---------------------------------------------------------------
            // Branch: la ALU resta para comparar (SUB)
            // ---------------------------------------------------------------
            2'b01: o_alu_ctrl = 4'b0110;

            // ---------------------------------------------------------------
            // Tipo R / Tipo I: decodificar segun funct3 y funct7
            // ---------------------------------------------------------------
            2'b10: begin
                case (i_funct3)
                    3'b000: begin // ADD / SUB / ADDI / MUL
                        // Solo es MUL o SUB si es Tipo R (i_op5 == 1).
                        // Para Tipo I (ADDI), el bit 30 es parte del inmediato,
                        // no de funct7, asi que debe ignorarse.
                        if (i_op5 && i_funct7_0) begin
                            // RV32M: MUL
                            o_mul_sel  = 1'b1;
                            o_alu_ctrl = 4'b0000;
                        end else if (i_op5 && i_funct7_5) begin
                            // SUB
                            o_alu_ctrl = 4'b0110;
                        end else begin
                            // ADD o ADDI
                            o_alu_ctrl = 4'b0010;
                        end
                    end

                    3'b001: o_alu_ctrl = 4'b0111; // SLL / SLLI

                    3'b010: o_alu_ctrl = 4'b1001; // SLT / SLTI

                    3'b011: o_alu_ctrl = 4'b1010; // SLTU / SLTIU

                    3'b100: o_alu_ctrl = 4'b0100; // XOR / XORI

                    3'b101: begin // SRL / SRA / SRLI / SRAI
                        // Para shifts, el bit 30 SI distingue logico/aritmetico
                        // tanto en Tipo R como en Tipo I (SRLI/SRAI)
                        if (i_funct7_5)
                            o_alu_ctrl = 4'b1000; // SRA / SRAI
                        else
                            o_alu_ctrl = 4'b0101; // SRL / SRLI
                    end

                    3'b110: o_alu_ctrl = 4'b0001; // OR / ORI

                    3'b111: o_alu_ctrl = 4'b0000; // AND / ANDI
                endcase
            end
        endcase
    end

endmodule
