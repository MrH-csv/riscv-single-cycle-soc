/***********************************************************
 * Descripcion:
 *   Testbench del sumador adder_4_32b. Verifica suma
 *   de 32 bits: casos basicos, conmutatividad, overflow
 *   (wrap-around) y valores limite.
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

module adder_4_32b_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [31:0] i_a;
    reg  [31:0] i_b;
    wire [31:0] o_sum;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    adder_4_32b #(.WIDTH(32)) dut (
        .i_a  (i_a),
        .i_b  (i_b),
        .o_sum(o_sum)
    );

    // --------------------------------------------------------
    // Contadores de resultado
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Tarea auxiliar: verificar una suma
    // --------------------------------------------------------
    task check;
        input [31:0] a;
        input [31:0] b;
        input [31:0] expected;
        begin
            i_a = a;
            i_b = b;
            #10;
            if (o_sum === expected) begin
                $display("[PASS] %0h + %0h = %0h", a, b, o_sum);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0h + %0h = %0h (esperado %0h)", a, b, o_sum, expected);
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
        $display(" Testbench: adder_4_32b");
        $display("=========================================");

        // Caso base
        check(32'h0000_0000, 32'h0000_0000, 32'h0000_0000);  // 0 + 0
        check(32'h0000_0001, 32'h0000_0000, 32'h0000_0001);  // 1 + 0
        check(32'h0000_0000, 32'h0000_0001, 32'h0000_0001);  // 0 + 1

        // Sumas basicas
        check(32'h0000_0001, 32'h0000_0001, 32'h0000_0002);  // 1 + 1
        check(32'h0000_0004, 32'h0000_0004, 32'h0000_0008);  // 4 + 4 (PC+4)
        check(32'h0000_000A, 32'h0000_0014, 32'h0000_001E);  // 10 + 20

        // Conmutatividad
        check(32'h0000_00FF, 32'h0000_0001, 32'h0000_0100);
        check(32'h0000_0001, 32'h0000_00FF, 32'h0000_0100);

        // Valores grandes
        check(32'h7FFF_FFFF, 32'h0000_0001, 32'h8000_0000);  // MAX_INT + 1
        check(32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0000);  // Wrap-around
        check(32'hFFFF_FFFF, 32'hFFFF_FFFF, 32'hFFFF_FFFE);  // -1 + -1

        // Patron tipico PC+4
        check(32'h0000_0000, 32'h0000_0004, 32'h0000_0004);
        check(32'h0000_0004, 32'h0000_0004, 32'h0000_0008);
        check(32'h0000_0008, 32'h0000_0004, 32'h0000_000C);
        check(32'h0000_000C, 32'h0000_0004, 32'h0000_0010);

        // Valores con bits alternados
        check(32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF);
        check(32'hDEAD_BEEF, 32'h0000_0000, 32'hDEAD_BEEF);

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