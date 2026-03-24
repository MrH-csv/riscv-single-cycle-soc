// ============================================================
// Testbench — mux_4i_1o
// Verifica seleccion correcta del multiplexor 4:1.
// ============================================================

`timescale 1ns/1ps

module mux_4i_1o_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [31:0] i_d0;
    reg  [31:0] i_d1;
    reg  [31:0] i_d2;
    reg  [31:0] i_d3;
    reg  [1:0]  i_sel;
    wire [31:0] o_out;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    mux_4i_1o #(.WIDTH(32)) dut (
        .i_d0 (i_d0),
        .i_d1 (i_d1),
        .i_d2 (i_d2),
        .i_d3 (i_d3),
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
        input [31:0] d2;
        input [31:0] d3;
        input [1:0]  sel;
        input [31:0] expected;
        begin
            i_d0  = d0;
            i_d1  = d1;
            i_d2  = d2;
            i_d3  = d3;
            i_sel = sel;
            #10;
            if (o_out === expected) begin
                $display("[PASS] sel=%b -> out=%08h", sel, o_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] sel=%b -> out=%08h (esperado %08h)", sel, o_out, expected);
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
        $display(" Testbench: mux_4i_1o");
        $display("=========================================");

        // Datos distintos en cada entrada, verificar seleccion
        check(32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444, 2'b00, 32'h1111_1111);
        check(32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444, 2'b01, 32'h2222_2222);
        check(32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444, 2'b10, 32'h3333_3333);
        check(32'h1111_1111, 32'h2222_2222, 32'h3333_3333, 32'h4444_4444, 2'b11, 32'h4444_4444);

        // Todas las entradas iguales
        check(32'hDEAD_BEEF, 32'hDEAD_BEEF, 32'hDEAD_BEEF, 32'hDEAD_BEEF, 2'b00, 32'hDEAD_BEEF);
        check(32'hDEAD_BEEF, 32'hDEAD_BEEF, 32'hDEAD_BEEF, 32'hDEAD_BEEF, 2'b11, 32'hDEAD_BEEF);

        // Todas cero
        check(32'h0, 32'h0, 32'h0, 32'h0, 2'b00, 32'h0);
        check(32'h0, 32'h0, 32'h0, 32'h0, 2'b10, 32'h0);

        // Solo una entrada tiene valor, las demas cero
        check(32'hCAFE_BABE, 32'h0, 32'h0, 32'h0, 2'b00, 32'hCAFE_BABE);
        check(32'h0, 32'hCAFE_BABE, 32'h0, 32'h0, 2'b01, 32'hCAFE_BABE);
        check(32'h0, 32'h0, 32'hCAFE_BABE, 32'h0, 2'b10, 32'hCAFE_BABE);
        check(32'h0, 32'h0, 32'h0, 32'hCAFE_BABE, 2'b11, 32'hCAFE_BABE);

        // Patrones alternados
        check(32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_0000, 32'h0000_FFFF, 2'b00, 32'hAAAA_AAAA);
        check(32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_0000, 32'h0000_FFFF, 2'b01, 32'h5555_5555);
        check(32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_0000, 32'h0000_FFFF, 2'b10, 32'hFFFF_0000);
        check(32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_0000, 32'h0000_FFFF, 2'b11, 32'h0000_FFFF);

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
