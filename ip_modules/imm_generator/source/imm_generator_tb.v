/***********************************************************
 * Descripcion:
 *   Testbench del generador de inmediatos. Verifica la
 *   generacion de inmediatos para todos los tipos de
 *   instruccion RV32I: I, S, B, U, J y default.
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

`timescale 1ns/1ps

module imm_generator_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [31:0] i_instr;
    wire [31:0] o_imm;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    imm_generator dut (
        .i_instr(i_instr),
        .o_imm  (o_imm)
    );

    // --------------------------------------------------------
    // Contadores de resultado
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Tarea auxiliar
    // --------------------------------------------------------
    task check;
        input [31:0] instr;
        input [31:0] expected;
        begin
            i_instr = instr;
            #10;
            if (o_imm === expected) begin
                $display("[PASS] instr=%08h -> imm=%08h", instr, o_imm);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] instr=%08h -> imm=%08h (esperado %08h)", instr, o_imm, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // Estimulos
    // --------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=========================================");
        $display(" Testbench: imm_generator");
        $display("=========================================");

        // =====================================================
        // I-type (opcode 0010011 = ADDI, etc.)
        // =====================================================
        // ADDI x1, x0, 1 -> 0x00100093, imm = 1
        check(32'h00100093, 32'h0000_0001);
        // ADDI x1, x0, -1 -> 0xFFF00093, imm = 0xFFFFFFFF
        check(32'hFFF00093, 32'hFFFF_FFFF);
        // ADDI x1, x0, 2047 -> 0x7FF00093, imm = 0x7FF
        check(32'h7FF00093, 32'h0000_07FF);

        // I-type Load (opcode 0000011)
        // LW x1, 4(x0) -> 0x00402083, imm = 4
        check(32'h00402083, 32'h0000_0004);

        // I-type JALR (opcode 1100111)
        // JALR x0, x1, 0 -> 0x000080E7... imm = 0
        check(32'h000080E7, 32'h0000_0000);

        // =====================================================
        // S-type (opcode 0100011)
        // =====================================================
        // SW x2, 4(x1) -> 0x0020A223, imm = 4
        check(32'h0020A223, 32'h0000_0004);
        // SW x2, -4(x1) -> imm bits: [31:25]=1111111, [11:7]=11100
        // Encoding: FFC0A023 -> verificamos
        // imm[11:5]=1111111 imm[4:0]=11100 -> imm = 0xFFFFFFFC = -4
        check(32'hFE20AE23, 32'hFFFF_FFFC);

        // =====================================================
        // B-type (opcode 1100011)
        // =====================================================
        // BEQ x0, x0, +8 -> 0x00000463, imm = 8
        check(32'h00000463, 32'h0000_0008);
        // BEQ con offset negativo: BEQ x0,x0,-4 -> FE000EE3, imm = -4
        check(32'hFE000EE3, 32'hFFFF_FFFC);

        // =====================================================
        // U-type (opcode 0110111 = LUI)
        // =====================================================
        // LUI x1, 0xDEADB -> 0xDEADB0B7, imm = 0xDEADB000
        check(32'hDEADB0B7, 32'hDEADB000);
        // AUIPC (opcode 0010111)
        // AUIPC x1, 0x00001 -> 0x00001097, imm = 0x00001000
        check(32'h00001097, 32'h0000_1000);

        // =====================================================
        // J-type (opcode 1101111 = JAL)
        // =====================================================
        // JAL x0, 0 -> 0x0000006F, imm = 0
        check(32'h0000006F, 32'h0000_0000);
        // JAL x1, +8 -> codificacion manual: imm[20|10:1|11|19:12]
        // offset=8 -> imm[20]=0, imm[10:1]=0000000100, imm[11]=0, imm[19:12]=00000000
        // [31:12] = 0_0000000100_0_00000000 = 00800
        check(32'h008000EF, 32'h0000_0008);

        // =====================================================
        // Default (R-type opcode 0110011 -> imm = 0)
        // =====================================================
        check(32'h002081B3, 32'h0000_0000);  // ADD x3,x1,x2

        // ---- Resumen ----
        $display("=========================================");
        $display(" Resultado: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("=========================================");

        if (fail_count == 0)
            $display(" >> TODOS LOS TESTS PASARON <<");
        else
            $display(" >> HAY FALLOS — revisar salida <<");

        $finish;
    end

endmodule
