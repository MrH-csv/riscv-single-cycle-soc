/***********************************************************
 * Descripcion:
 *   Testbench de la unidad de branch. Verifica la
 *   logica de comparacion para todas las condiciones
 *   de branch RV32I y saltos incondicionales (jump).
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

module branch_unit_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [31:0] i_rs1_data;
    reg  [31:0] i_rs2_data;
    reg  [2:0]  i_funct3;
    reg         i_branch;
    reg         i_jump;
    wire        o_pc_sel;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    branch_unit dut (
        .i_rs1_data (i_rs1_data),
        .i_rs2_data (i_rs2_data),
        .i_funct3   (i_funct3),
        .i_branch   (i_branch),
        .i_jump     (i_jump),
        .o_pc_sel   (o_pc_sel)
    );

    // --------------------------------------------------------
    // Contadores de resultado
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Tarea auxiliar de verificacion
    // --------------------------------------------------------
    task check;
        input [31:0] rs1;
        input [31:0] rs2;
        input [2:0]  funct3;
        input        branch;
        input        jump;
        input        exp_pc_sel;
        begin
            i_rs1_data = rs1;
            i_rs2_data = rs2;
            i_funct3   = funct3;
            i_branch   = branch;
            i_jump     = jump;
            #10;
            if (o_pc_sel === exp_pc_sel) begin
                $display("[PASS] rs1=0x%08h rs2=0x%08h f3=%b br=%b jmp=%b -> pc_sel=%b",
                         rs1, rs2, funct3, branch, jump, o_pc_sel);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] rs1=0x%08h rs2=0x%08h f3=%b br=%b jmp=%b -> got=%b exp=%b",
                         rs1, rs2, funct3, branch, jump, o_pc_sel, exp_pc_sel);
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
        $display(" Testbench: branch_unit");
        $display("=========================================");

        // ---- BEQ (funct3=000) ----
        $display("\n--- BEQ ---");
        check(32'd5,  32'd5,  3'b000, 1, 0, 1);  // 5 == 5 -> taken
        check(32'd5,  32'd10, 3'b000, 1, 0, 0);  // 5 != 10 -> not taken

        // ---- BNE (funct3=001) ----
        $display("\n--- BNE ---");
        check(32'd5,  32'd10, 3'b001, 1, 0, 1);  // 5 != 10 -> taken
        check(32'd7,  32'd7,  3'b001, 1, 0, 0);  // 7 == 7 -> not taken

        // ---- BLT (funct3=100, signed) ----
        $display("\n--- BLT (signed) ---");
        check(32'hFFFF_FFFF, 32'd1,          3'b100, 1, 0, 1);  // -1 < 1 -> taken
        check(32'd5,         32'd3,          3'b100, 1, 0, 0);  // 5 >= 3 -> not taken
        check(32'd3,         32'd3,          3'b100, 1, 0, 0);  // 3 == 3 -> not taken

        // ---- BGE (funct3=101, signed) ----
        $display("\n--- BGE (signed) ---");
        check(32'd10, 32'd5,          3'b101, 1, 0, 1);  // 10 >= 5 -> taken
        check(32'd5,  32'd5,          3'b101, 1, 0, 1);  // 5 >= 5 -> taken
        check(32'd1,  32'd5,          3'b101, 1, 0, 0);  // 1 < 5 -> not taken

        // ---- BLTU (funct3=110, unsigned) ----
        $display("\n--- BLTU (unsigned) ---");
        check(32'd1,          32'hFFFF_FFFF, 3'b110, 1, 0, 1);  // 1 < 0xFFFFFFFF -> taken
        check(32'hFFFF_FFFF,  32'd1,         3'b110, 1, 0, 0);  // 0xFFFFFFFF >= 1 -> not taken

        // ---- BGEU (funct3=111, unsigned) ----
        $display("\n--- BGEU (unsigned) ---");
        check(32'hFFFF_FFFF, 32'd1,          3'b111, 1, 0, 1);  // 0xFFFFFFFF >= 1 -> taken
        check(32'd5,         32'd5,          3'b111, 1, 0, 1);  // 5 >= 5 -> taken
        check(32'd0,         32'd1,          3'b111, 1, 0, 0);  // 0 < 1 -> not taken

        // ---- Jump incondicional (JAL/JALR) ----
        $display("\n--- Jump (incondicional) ---");
        check(32'd0, 32'd0, 3'b000, 0, 1, 1);  // jump=1 -> siempre taken
        check(32'd0, 32'd0, 3'b101, 0, 1, 1);  // jump=1, cualquier funct3

        // ---- Branch deshabilitado ----
        $display("\n--- Branch deshabilitado ---");
        check(32'd5, 32'd5, 3'b000, 0, 0, 0);  // branch=0, jump=0 -> no taken

        // ---- Resumen ----
        $display("\n=========================================");
        $display(" Resultado: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("=========================================");

        if (fail_count == 0)
            $display(" >> TODOS LOS TESTS PASARON <<");
        else
            $display(" >> HAY FALLOS — revisar salida <<");

        $finish;
    end

endmodule
