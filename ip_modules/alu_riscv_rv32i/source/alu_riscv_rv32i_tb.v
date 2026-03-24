// ============================================================
// Testbench — alu_riscv_rv32i
// Verifica las 10 operaciones de la ALU RV32I y la bandera zero.
// ============================================================

`timescale 1ns/1ps

module alu_riscv_rv32i_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [31:0] i_a;
    reg  [31:0] i_b;
    reg  [3:0]  i_alu_ctrl;
    wire [31:0] o_result;
    wire        o_zero;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    alu_riscv_rv32i #(.WIDTH(32)) dut (
        .i_a       (i_a),
        .i_b       (i_b),
        .i_alu_ctrl(i_alu_ctrl),
        .o_result  (o_result),
        .o_zero    (o_zero)
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
        input [31:0] a;
        input [31:0] b;
        input [3:0]  ctrl;
        input [31:0] exp_result;
        input        exp_zero;
        begin
            i_a        = a;
            i_b        = b;
            i_alu_ctrl = ctrl;
            #10;
            if (o_result === exp_result && o_zero === exp_zero) begin
                $display("[PASS] ctrl=%b  a=%08h  b=%08h  -> result=%08h  zero=%b",
                         ctrl, a, b, o_result, o_zero);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] ctrl=%b  a=%08h  b=%08h  -> result=%08h (exp %08h)  zero=%b (exp %b)",
                         ctrl, a, b, o_result, exp_result, o_zero, exp_zero);
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
        $display(" Testbench: alu_riscv_rv32i");
        $display("=========================================");

        // --- AND (0000) ---
        check(32'hFFFF_FFFF, 32'h0F0F_0F0F, 4'b0000, 32'h0F0F_0F0F, 1'b0);
        check(32'hAAAA_AAAA, 32'h5555_5555, 4'b0000, 32'h0000_0000, 1'b1);

        // --- OR (0001) ---
        check(32'hAAAA_AAAA, 32'h5555_5555, 4'b0001, 32'hFFFF_FFFF, 1'b0);
        check(32'h0000_0000, 32'h0000_0000, 4'b0001, 32'h0000_0000, 1'b1);

        // --- ADD (0010) ---
        check(32'h0000_000A, 32'h0000_0014, 4'b0010, 32'h0000_001E, 1'b0);
        check(32'hFFFF_FFFF, 32'h0000_0001, 4'b0010, 32'h0000_0000, 1'b1);  // wrap + zero
        check(32'h7FFF_FFFF, 32'h0000_0001, 4'b0010, 32'h8000_0000, 1'b0);

        // --- XOR (0100) ---
        check(32'hFFFF_FFFF, 32'hFFFF_FFFF, 4'b0100, 32'h0000_0000, 1'b1);
        check(32'hAAAA_AAAA, 32'h5555_5555, 4'b0100, 32'hFFFF_FFFF, 1'b0);

        // --- SRL (0101) ---
        check(32'h8000_0000, 32'h0000_0001, 4'b0101, 32'h4000_0000, 1'b0);  // logical shift
        check(32'hFFFF_FFFF, 32'h0000_0010, 4'b0101, 32'h0000_FFFF, 1'b0);  // >>16

        // --- SUB (0110) ---
        check(32'h0000_000A, 32'h0000_000A, 4'b0110, 32'h0000_0000, 1'b1);  // zero flag
        check(32'h0000_0014, 32'h0000_000A, 4'b0110, 32'h0000_000A, 1'b0);
        check(32'h0000_0000, 32'h0000_0001, 4'b0110, 32'hFFFF_FFFF, 1'b0);  // underflow

        // --- SLL (0111) ---
        check(32'h0000_0001, 32'h0000_0004, 4'b0111, 32'h0000_0010, 1'b0);  // 1<<4
        check(32'h0000_0001, 32'h0000_001F, 4'b0111, 32'h8000_0000, 1'b0);  // 1<<31

        // --- SRA (1000) ---
        check(32'h8000_0000, 32'h0000_0004, 4'b1000, 32'hF800_0000, 1'b0);  // arithmetic
        check(32'h7FFF_FFFF, 32'h0000_0004, 4'b1000, 32'h07FF_FFFF, 1'b0);  // positive

        // --- SLT signed (1001) ---
        check(32'hFFFF_FFFF, 32'h0000_0001, 4'b1001, 32'h0000_0001, 1'b0);  // -1 < 1
        check(32'h0000_0001, 32'hFFFF_FFFF, 4'b1001, 32'h0000_0000, 1'b1);  // 1 > -1
        check(32'h0000_0005, 32'h0000_0005, 4'b1001, 32'h0000_0000, 1'b1);  // equal

        // --- SLTU unsigned (1010) ---
        check(32'h0000_0001, 32'hFFFF_FFFF, 4'b1010, 32'h0000_0001, 1'b0);  // 1 < 0xFFFFFFFF
        check(32'hFFFF_FFFF, 32'h0000_0001, 4'b1010, 32'h0000_0000, 1'b1);  // opposite
        check(32'h0000_000A, 32'h0000_000A, 4'b1010, 32'h0000_0000, 1'b1);  // equal

        // --- Default (undefined ctrl) ---
        check(32'h1234_5678, 32'h9ABC_DEF0, 4'b0011, 32'h0000_0000, 1'b1);
        check(32'h1234_5678, 32'h9ABC_DEF0, 4'b1111, 32'h0000_0000, 1'b1);

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
