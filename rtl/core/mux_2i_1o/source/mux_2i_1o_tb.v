/***********************************************************
 * Descripcion:
 *   Testbench del multiplexor 2:1. Verifica la seleccion
 *   correcta de entradas.
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

module mux_2i_1o_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [31:0] i_d0;
    reg  [31:0] i_d1;
    reg         i_sel;
    wire [31:0] o_out;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    mux_2i_1o #(.WIDTH(32)) dut (
        .i_d0 (i_d0),
        .i_d1 (i_d1),
        .i_sel(i_sel),
        .o_out(o_out)
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
        input [31:0] d0;
        input [31:0] d1;
        input        sel;
        input [31:0] expected;
        begin
            i_d0  = d0;
            i_d1  = d1;
            i_sel = sel;
            #10;
            if (o_out === expected) begin
                $display("[PASS] d0=%08h d1=%08h sel=%b -> out=%08h", d0, d1, sel, o_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] d0=%08h d1=%08h sel=%b -> out=%08h (esperado %08h)",
                         d0, d1, sel, o_out, expected);
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
        $display(" Testbench: mux_2i_1o");
        $display("=========================================");

        // sel=0 selecciona d0
        check(32'hAAAA_AAAA, 32'h5555_5555, 1'b0, 32'hAAAA_AAAA);
        // sel=1 selecciona d1
        check(32'hAAAA_AAAA, 32'h5555_5555, 1'b1, 32'h5555_5555);

        // Ambos cero
        check(32'h0000_0000, 32'h0000_0000, 1'b0, 32'h0000_0000);
        check(32'h0000_0000, 32'h0000_0000, 1'b1, 32'h0000_0000);

        // Ambos max
        check(32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b0, 32'hFFFF_FFFF);
        check(32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, 32'hFFFF_FFFF);

        // Valores distintos
        check(32'hDEAD_BEEF, 32'hCAFE_BABE, 1'b0, 32'hDEAD_BEEF);
        check(32'hDEAD_BEEF, 32'hCAFE_BABE, 1'b1, 32'hCAFE_BABE);

        // Verificar que cambia al toggle de sel
        check(32'h1234_5678, 32'h9ABC_DEF0, 1'b0, 32'h1234_5678);
        check(32'h1234_5678, 32'h9ABC_DEF0, 1'b1, 32'h9ABC_DEF0);

        // Entrada no seleccionada no afecta salida
        check(32'h0000_0001, 32'hFFFF_FFFF, 1'b0, 32'h0000_0001);
        check(32'hFFFF_FFFF, 32'h0000_0001, 1'b1, 32'h0000_0001);

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
