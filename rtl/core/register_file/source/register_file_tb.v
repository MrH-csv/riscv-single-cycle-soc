/***********************************************************
 * Descripcion:
 *   Testbench del banco de registros RV32I. Verifica
 *   x0 hardwired, escritura sincrona, lectura
 *   combinacional y write enable.
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

module register_file_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg         clk;
    reg         i_we;
    reg  [4:0]  i_rd;
    reg  [31:0] i_wdata;
    reg  [4:0]  i_rs1;
    wire [31:0] o_rdata1;
    reg  [4:0]  i_rs2;
    wire [31:0] o_rdata2;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    register_file #(.WIDTH(32)) dut (
        .clk     (clk),
        .i_we    (i_we),
        .i_rd    (i_rd),
        .i_wdata (i_wdata),
        .i_rs1   (i_rs1),
        .o_rdata1(o_rdata1),
        .i_rs2   (i_rs2),
        .o_rdata2(o_rdata2)
    );

    // --------------------------------------------------------
    // Generador de reloj (periodo 10 ns)
    // --------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------------------------------------
    // Contadores de resultado
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Tarea auxiliar: escribir un registro (espera 1 ciclo)
    // --------------------------------------------------------
    task write_reg;
        input [4:0]  rd;
        input [31:0] wdata;
        begin
            @(negedge clk);
            i_we    = 1;
            i_rd    = rd;
            i_wdata = wdata;
            @(posedge clk);
            #1;
            i_we = 0;
        end
    endtask

    // --------------------------------------------------------
    // Tarea auxiliar: verificar lectura (combinacional)
    // --------------------------------------------------------
    task check_read;
        input [4:0]  rs;
        input [31:0] expected;
        input        port; // 0 = rs1, 1 = rs2
        begin
            if (port == 0) begin
                i_rs1 = rs;
                #1;
                if (o_rdata1 === expected) begin
                    $display("[PASS] rs1=x%0d -> %08h", rs, o_rdata1);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL] rs1=x%0d -> %08h (esperado %08h)", rs, o_rdata1, expected);
                    fail_count = fail_count + 1;
                end
            end else begin
                i_rs2 = rs;
                #1;
                if (o_rdata2 === expected) begin
                    $display("[PASS] rs2=x%0d -> %08h", rs, o_rdata2);
                    pass_count = pass_count + 1;
                end else begin
                    $display("[FAIL] rs2=x%0d -> %08h (esperado %08h)", rs, o_rdata2, expected);
                    fail_count = fail_count + 1;
                end
            end
        end
    endtask

    // --------------------------------------------------------
    // Estimulos
    // --------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        i_we    = 0;
        i_rd    = 5'd0;
        i_wdata = 32'd0;
        i_rs1   = 5'd0;
        i_rs2   = 5'd0;

        $display("=========================================");
        $display(" Testbench: register_file");
        $display("=========================================");

        // Esperar un ciclo para estabilizar
        @(posedge clk);
        #1;

        // --- Test 1: x0 siempre lee 0 ---
        check_read(5'd0, 32'h0, 0);
        check_read(5'd0, 32'h0, 1);

        // --- Test 2: Escribir a x0 debe ser ignorado ---
        write_reg(5'd0, 32'hDEAD_BEEF);
        check_read(5'd0, 32'h0, 0);
        check_read(5'd0, 32'h0, 1);

        // --- Test 3: Escribir a x1 y leer por ambos puertos ---
        write_reg(5'd1, 32'h0000_0001);
        check_read(5'd1, 32'h0000_0001, 0);
        check_read(5'd1, 32'h0000_0001, 1);

        // --- Test 4: Escribir a x2 ---
        write_reg(5'd2, 32'h0000_0002);
        check_read(5'd2, 32'h0000_0002, 0);

        // --- Test 5: Lectura simultanea de dos registros distintos ---
        i_rs1 = 5'd1;
        i_rs2 = 5'd2;
        #1;
        if (o_rdata1 === 32'h0000_0001 && o_rdata2 === 32'h0000_0002) begin
            $display("[PASS] Lectura simultanea: x1=%08h x2=%08h", o_rdata1, o_rdata2);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Lectura simultanea: x1=%08h x2=%08h", o_rdata1, o_rdata2);
            fail_count = fail_count + 1;
        end

        // --- Test 6: we=0 no debe escribir ---
        @(negedge clk);
        i_we    = 0;
        i_rd    = 5'd3;
        i_wdata = 32'hBAD0_BAD0;
        @(posedge clk);
        #1;
        // x3 no debe tener el valor escrito (sera X o 0 si no se inicializo)
        // Verificamos que NO sea BAD0BAD0
        i_rs1 = 5'd3;
        #1;
        if (o_rdata1 !== 32'hBAD0_BAD0) begin
            $display("[PASS] we=0: x3 no se escribio (%08h != BAD0BAD0)", o_rdata1);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] we=0: x3 se escribio incorrectamente (%08h)", o_rdata1);
            fail_count = fail_count + 1;
        end

        // --- Test 7: Escribir a registros altos (x31) ---
        write_reg(5'd31, 32'hCAFE_BABE);
        check_read(5'd31, 32'hCAFE_BABE, 0);

        // --- Test 8: Sobrescribir un registro ---
        write_reg(5'd1, 32'hFFFF_FFFF);
        check_read(5'd1, 32'hFFFF_FFFF, 0);

        // --- Test 9: x0 sigue siendo 0 despues de todo ---
        check_read(5'd0, 32'h0, 0);

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
