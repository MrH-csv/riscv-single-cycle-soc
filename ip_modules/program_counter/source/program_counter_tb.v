// ============================================================
// Testbench — program_counter
// Verifica reset sincrono, enable, hold y operacion secuencial.
// ============================================================

`timescale 1ns/1ps

module program_counter_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         en;
    reg  [31:0] i_next_pc;
    wire [31:0] o_pc;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    program_counter #(.WIDTH(32), .RESET_VECTOR(32'h0000_0000)) dut (
        .clk      (clk),
        .rst      (rst),
        .en       (en),
        .i_next_pc(i_next_pc),
        .o_pc     (o_pc)
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
    // Tarea auxiliar: verificar despues de posedge clk
    // --------------------------------------------------------
    task check;
        input [31:0] expected;
        begin
            @(posedge clk);
            #1; // pequeno retardo para estabilizar
            if (o_pc === expected) begin
                $display("[PASS] o_pc=%08h", o_pc);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] o_pc=%08h (esperado %08h)", o_pc, expected);
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
        rst       = 1;
        en        = 0;
        i_next_pc = 32'h0;

        $display("=========================================");
        $display(" Testbench: program_counter");
        $display("=========================================");

        // --- Test 1: Reset ---
        // rst=1, en=0 -> PC debe ir a RESET_VECTOR (0)
        check(32'h0000_0000);

        // --- Test 2: Reset tiene prioridad sobre enable ---
        en        = 1;
        i_next_pc = 32'hDEAD_BEEF;
        check(32'h0000_0000);  // rst=1 tiene prioridad

        // --- Test 3: Liberar reset, cargar PC+4 ---
        rst       = 0;
        en        = 1;
        i_next_pc = 32'h0000_0004;
        check(32'h0000_0004);

        // --- Test 4: Secuencia PC+4 ---
        i_next_pc = 32'h0000_0008;
        check(32'h0000_0008);

        i_next_pc = 32'h0000_000C;
        check(32'h0000_000C);

        i_next_pc = 32'h0000_0010;
        check(32'h0000_0010);

        // --- Test 5: Hold (en=0) ---
        en        = 0;
        i_next_pc = 32'hFFFF_FFFF;
        check(32'h0000_0010);  // debe mantener el valor anterior

        // Otro ciclo de hold
        check(32'h0000_0010);

        // --- Test 6: Re-enable ---
        en        = 1;
        i_next_pc = 32'h0000_0100;
        check(32'h0000_0100);

        // --- Test 7: Salto (branch target) ---
        i_next_pc = 32'h0000_0400;
        check(32'h0000_0400);

        // --- Test 8: Reset en medio de operacion ---
        rst       = 1;
        i_next_pc = 32'hBAAD_F00D;
        check(32'h0000_0000);

        // Liberar reset
        rst = 0;
        i_next_pc = 32'h0000_0004;
        check(32'h0000_0004);

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
