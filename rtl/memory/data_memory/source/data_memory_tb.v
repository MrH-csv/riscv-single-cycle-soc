/***********************************************************
 * Descripcion:
 *   Testbench de la memoria de datos RAM. Verifica
 *   lectura/escritura para el procesador RISC-V RV32I
 *   single-cycle.
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

module data_memory_tb;

    // --------------------------------------------------------
    // Parametros
    // --------------------------------------------------------
    parameter DEPTH = 64;
    parameter CLK_PERIOD = 10;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg         clk;
    reg         i_mem_write;
    reg         i_mem_read;
    reg  [31:0] i_addr;
    reg  [31:0] i_wdata;
    wire [31:0] o_rdata;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    data_memory #(
        .DEPTH(DEPTH)
    ) dut (
        .clk        (clk),
        .i_mem_write(i_mem_write),
        .i_mem_read (i_mem_read),
        .i_addr     (i_addr),
        .i_wdata    (i_wdata),
        .o_rdata    (o_rdata)
    );

    // --------------------------------------------------------
    // Generacion de reloj
    // --------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // --------------------------------------------------------
    // Contadores de resultado
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Tarea auxiliar: escribe un dato en memoria
    // --------------------------------------------------------
    task write_mem;
        input [31:0] addr;
        input [31:0] data;
        begin
            i_mem_write = 1'b1;
            i_mem_read  = 1'b0;
            i_addr      = addr;
            i_wdata     = data;
            @(posedge clk);
            #1;
            i_mem_write = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // Tarea auxiliar: lee y verifica un dato de memoria
    // --------------------------------------------------------
    task check_read;
        input [31:0] addr;
        input [31:0] expected;
        begin
            i_mem_write = 1'b0;
            i_mem_read  = 1'b1;
            i_addr      = addr;
            #1;
            if (o_rdata === expected) begin
                $display("[PASS] addr=0x%08h -> data=0x%08h", addr, o_rdata);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] addr=0x%08h -> got=0x%08h, exp=0x%08h",
                         addr, o_rdata, expected);
                fail_count = fail_count + 1;
            end
            i_mem_read = 1'b0;
        end
    endtask

    // --------------------------------------------------------
    // Estimulos
    // --------------------------------------------------------
    initial begin
        pass_count  = 0;
        fail_count  = 0;
        i_mem_write = 0;
        i_mem_read  = 0;
        i_addr      = 0;
        i_wdata     = 0;

        $display("=========================================");
        $display(" Testbench: data_memory");
        $display("=========================================");

        // Esperar un ciclo
        @(posedge clk);
        #1;

        // ---- Test 1: Escribir y leer palabra en dir 0 ----
        $display("\n--- Test 1: Escritura/Lectura dir 0x00 ---");
        write_mem(32'h0000_0000, 32'hDEAD_BEEF);
        check_read(32'h0000_0000, 32'hDEAD_BEEF);

        // ---- Test 2: Escribir y leer en dir 4 ----
        $display("\n--- Test 2: Escritura/Lectura dir 0x04 ---");
        write_mem(32'h0000_0004, 32'hCAFE_BABE);
        check_read(32'h0000_0004, 32'hCAFE_BABE);

        // ---- Test 3: Escribir y leer en dir 8 ----
        $display("\n--- Test 3: Escritura/Lectura dir 0x08 ---");
        write_mem(32'h0000_0008, 32'h1234_5678);
        check_read(32'h0000_0008, 32'h1234_5678);

        // ---- Test 4: Verificar que dir 0 sigue intacta ----
        $display("\n--- Test 4: Re-lectura dir 0x00 (persistencia) ---");
        check_read(32'h0000_0000, 32'hDEAD_BEEF);

        // ---- Test 5: Sobreescritura ----
        $display("\n--- Test 5: Sobreescritura dir 0x00 ---");
        write_mem(32'h0000_0000, 32'h0000_0042);
        check_read(32'h0000_0000, 32'h0000_0042);

        // ---- Test 6: mem_read=0 retorna 0 ----
        $display("\n--- Test 6: Lectura deshabilitada retorna 0 ---");
        i_mem_read  = 1'b0;
        i_mem_write = 1'b0;
        i_addr      = 32'h0000_0004;
        #1;
        if (o_rdata === 32'h0000_0000) begin
            $display("[PASS] mem_read=0 -> data=0x%08h", o_rdata);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] mem_read=0 -> got=0x%08h, exp=0x00000000", o_rdata);
            fail_count = fail_count + 1;
        end

        // ---- Test 7: mem_write=0 NO escribe ----
        $display("\n--- Test 7: Escritura deshabilitada no modifica ---");
        i_mem_write = 1'b0;
        i_mem_read  = 1'b0;
        i_addr      = 32'h0000_0004;
        i_wdata     = 32'hFFFF_FFFF;
        @(posedge clk);
        #1;
        check_read(32'h0000_0004, 32'hCAFE_BABE);

        // ---- Test 8: Escribir en direccion alta ----
        $display("\n--- Test 8: Escritura/Lectura dir alta ---");
        write_mem(32'h0000_00FC, 32'hABCD_EF01);
        check_read(32'h0000_00FC, 32'hABCD_EF01);

        // ---- Test 9: Alineacion — bits [1:0] ignorados ----
        $display("\n--- Test 9: Alineacion de direccion (bits[1:0] ignorados) ---");
        write_mem(32'h0000_0010, 32'hAAAA_BBBB);
        // Leer con dir 0x12 y 0x13 debe dar el mismo resultado (misma palabra)
        check_read(32'h0000_0012, 32'hAAAA_BBBB);
        check_read(32'h0000_0013, 32'hAAAA_BBBB);

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
