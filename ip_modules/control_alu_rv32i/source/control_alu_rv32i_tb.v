// ============================================================
// Testbench — control_alu_rv32i
// Verifica decodificacion de ALU control para RV32I/M.
// Incluye prueba del bug guard de ADDI (i_op5).
//
// Senales de verificacion visibles en el Wave viewer:
//   test_num      - Numero de test actual
//   test_pass     - 1 si el test paso, 0 si fallo
//   exp_alu_ctrl  - Valor esperado de o_alu_ctrl
//   exp_mul_sel   - Valor esperado de o_mul_sel
//   ctrl_match    - 1 si o_alu_ctrl == exp_alu_ctrl
//   mul_match     - 1 si o_mul_sel  == exp_mul_sel
// ============================================================

`timescale 1ns/1ps

module control_alu_rv32i_tb;

    // --------------------------------------------------------
    // Senales del DUT
    // --------------------------------------------------------
    reg  [1:0] i_alu_op;
    reg  [2:0] i_funct3;
    reg        i_funct7_5;
    reg        i_funct7_0;
    reg        i_op5;
    wire [3:0] o_alu_ctrl;
    wire       o_mul_sel;

    // --------------------------------------------------------
    // Senales de verificacion (visibles en Wave viewer)
    // --------------------------------------------------------
    reg  [7:0]  test_num;       // Numero de test (1, 2, 3, ...)
    reg  [3:0]  exp_alu_ctrl;   // Valor esperado de alu_ctrl
    reg         exp_mul_sel;    // Valor esperado de mul_sel
    wire        ctrl_match;     // 1 si alu_ctrl coincide con esperado
    wire        mul_match;      // 1 si mul_sel coincide con esperado
    wire        test_pass;      // 1 si AMBOS coinciden (test pasa)

    assign ctrl_match = (o_alu_ctrl === exp_alu_ctrl);
    assign mul_match  = (o_mul_sel  === exp_mul_sel);
    assign test_pass  = ctrl_match & mul_match;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    control_alu_rv32i dut (
        .i_alu_op   (i_alu_op),
        .i_funct3   (i_funct3),
        .i_funct7_5 (i_funct7_5),
        .i_funct7_0 (i_funct7_0),
        .i_op5      (i_op5),
        .o_alu_ctrl (o_alu_ctrl),
        .o_mul_sel  (o_mul_sel)
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
        input [1:0] aop;
        input [2:0] f3;
        input       f7_5;
        input       f7_0;
        input       op5;
        input [3:0] e_ctrl;
        input       e_mul;
        begin
            // Aplicar estimulos
            i_alu_op    = aop;
            i_funct3    = f3;
            i_funct7_5  = f7_5;
            i_funct7_0  = f7_0;
            i_op5       = op5;

            // Registrar valores esperados (visibles en Wave)
            exp_alu_ctrl = e_ctrl;
            exp_mul_sel  = e_mul;
            test_num     = test_num + 1;

            #10; // retardo de propagacion

            // Verificar y reportar en consola
            if (test_pass) begin
                $display("[PASS] Test %0d: alu_op=%b f3=%b f7_5=%b f7_0=%b op5=%b -> ctrl=%b mul=%b",
                         test_num, aop, f3, f7_5, f7_0, op5, o_alu_ctrl, o_mul_sel);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: alu_op=%b f3=%b f7_5=%b f7_0=%b op5=%b -> ctrl=%b (exp %b) mul=%b (exp %b)",
                         test_num, aop, f3, f7_5, f7_0, op5, o_alu_ctrl, e_ctrl, o_mul_sel, e_mul);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // Estimulos
    // --------------------------------------------------------
    initial begin
        pass_count   = 0;
        fail_count   = 0;
        test_num     = 0;
        exp_alu_ctrl = 4'b0000;
        exp_mul_sel  = 1'b0;

        $display("=========================================");
        $display(" Testbench: control_alu_rv32i");
        $display("=========================================");

        // --- alu_op = 00: Load/Store -> ADD ---
        //           aop  f3   f75 f70 op5  exp_ctrl exp_mul
        check(2'b00, 3'b000, 0, 0, 0, 4'b0010, 0);
        check(2'b00, 3'b010, 1, 0, 1, 4'b0010, 0);  // funct3 irrelevante

        // --- alu_op = 01: Branch -> SUB ---
        check(2'b01, 3'b000, 0, 0, 0, 4'b0110, 0);
        check(2'b01, 3'b001, 1, 1, 1, 4'b0110, 0);  // funct3 irrelevante

        // --- alu_op = 10: R-type (i_op5=1) ---

        // ADD: funct3=000, funct7_5=0, funct7_0=0, R-type
        check(2'b10, 3'b000, 0, 0, 1, 4'b0010, 0);

        // SUB: funct3=000, funct7_5=1, funct7_0=0, R-type
        check(2'b10, 3'b000, 1, 0, 1, 4'b0110, 0);

        // MUL: funct3=000, funct7_0=1, R-type
        check(2'b10, 3'b000, 0, 1, 1, 4'b0000, 1);

        // SLL: funct3=001
        check(2'b10, 3'b001, 0, 0, 1, 4'b0111, 0);

        // SLT: funct3=010
        check(2'b10, 3'b010, 0, 0, 1, 4'b1001, 0);

        // SLTU: funct3=011
        check(2'b10, 3'b011, 0, 0, 1, 4'b1010, 0);

        // XOR: funct3=100
        check(2'b10, 3'b100, 0, 0, 1, 4'b0100, 0);

        // SRL: funct3=101, funct7_5=0
        check(2'b10, 3'b101, 0, 0, 1, 4'b0101, 0);

        // SRA: funct3=101, funct7_5=1
        check(2'b10, 3'b101, 1, 0, 1, 4'b1000, 0);

        // OR: funct3=110
        check(2'b10, 3'b110, 0, 0, 1, 4'b0001, 0);

        // AND: funct3=111
        check(2'b10, 3'b111, 0, 0, 1, 4'b0000, 0);

        // --- alu_op = 10: I-type (i_op5=0) ---

        // ADDI: funct3=000, i_op5=0 -> debe dar ADD aunque funct7_5=1
        // ESTA ES LA PRUEBA CRITICA DEL BUG GUARD
        check(2'b10, 3'b000, 0, 0, 0, 4'b0010, 0);  // ADDI normal
        check(2'b10, 3'b000, 1, 0, 0, 4'b0010, 0);  // ADDI con bit30=1 -> NO debe ser SUB

        // SLLI: funct3=001, I-type
        check(2'b10, 3'b001, 0, 0, 0, 4'b0111, 0);

        // SLTI: funct3=010, I-type
        check(2'b10, 3'b010, 0, 0, 0, 4'b1001, 0);

        // SLTIU: funct3=011, I-type
        check(2'b10, 3'b011, 0, 0, 0, 4'b1010, 0);

        // XORI: funct3=100, I-type
        check(2'b10, 3'b100, 0, 0, 0, 4'b0100, 0);

        // SRLI: funct3=101, funct7_5=0, I-type
        check(2'b10, 3'b101, 0, 0, 0, 4'b0101, 0);

        // SRAI: funct3=101, funct7_5=1, I-type
        check(2'b10, 3'b101, 1, 0, 0, 4'b1000, 0);

        // ORI: funct3=110, I-type
        check(2'b10, 3'b110, 0, 0, 0, 4'b0001, 0);

        // ANDI: funct3=111, I-type
        check(2'b10, 3'b111, 0, 0, 0, 4'b0000, 0);

        // I-type con funct7_0=1 pero i_op5=0 -> NO debe activar MUL
        check(2'b10, 3'b000, 0, 1, 0, 4'b0010, 0);

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
