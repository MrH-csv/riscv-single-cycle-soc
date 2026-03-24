// ============================================================
// Testbench — mul_module
// Verifica multiplicacion de 32 bits (parte baja del producto).
// ============================================================

`timescale 1ns/1ps

module mul_module_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [31:0] i_a;
    reg  [31:0] i_b;
    wire [31:0] o_result;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    mul_module #(.WIDTH(32)) dut (
        .i_a     (i_a),
        .i_b     (i_b),
        .o_result(o_result)
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
        input [31:0] expected;
        begin
            i_a = a;
            i_b = b;
            #10;
            if (o_result === expected) begin
                $display("[PASS] %0h * %0h = %0h", a, b, o_result);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0h * %0h = %0h (esperado %0h)", a, b, o_result, expected);
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
        $display(" Testbench: mul_module");
        $display("=========================================");

        // Casos basicos
        check(32'd0, 32'd0, 32'd0);           // 0 * 0
        check(32'd1, 32'd1, 32'd1);           // 1 * 1
        check(32'd1, 32'd0, 32'd0);           // 1 * 0
        check(32'd0, 32'd1, 32'd0);           // 0 * 1

        // Multiplicaciones simples
        check(32'd2,  32'd3,  32'd6);
        check(32'd7,  32'd11, 32'd77);
        check(32'd100, 32'd200, 32'd20000);

        // Conmutatividad
        check(32'd123, 32'd456, 32'd56088);
        check(32'd456, 32'd123, 32'd56088);

        // Potencias de 2 (equivalente a shift)
        check(32'd1,   32'd1024, 32'd1024);
        check(32'd256, 32'd256,  32'd65536);

        // Overflow: solo parte baja de 32 bits
        // 0x10000 * 0x10000 = 0x100000000 -> lower 32 = 0
        check(32'h0001_0000, 32'h0001_0000, 32'h0000_0000);
        // 0xFFFFFFFF * 2 = 0x1FFFFFFFE -> lower 32 = 0xFFFFFFFE
        check(32'hFFFF_FFFF, 32'h0000_0002, 32'hFFFF_FFFE);
        // 0xFFFFFFFF * 0xFFFFFFFF -> lower 32 = 1
        check(32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'h0000_0001);

        // Identidad multiplicativa
        check(32'hDEAD_BEEF, 32'h0000_0001, 32'hDEAD_BEEF);
        check(32'h0000_0001, 32'hCAFE_BABE, 32'hCAFE_BABE);

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
