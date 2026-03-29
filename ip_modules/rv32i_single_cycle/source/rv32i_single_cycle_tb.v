// ============================================================
// Testbench — rv32i_single_cycle
// Testbench de sistema para el procesador RISC-V RV32I
// single-cycle completo. Ejecuta un programa desde la ROM
// y verifica el estado final de los registros y memoria.
// ============================================================

`timescale 1ns/1ps

module rv32i_single_cycle_tb;

    // --------------------------------------------------------
    // Parametros
    // --------------------------------------------------------
    parameter CLK_PERIOD  = 10;       // 100 MHz
    parameter IMEM_DEPTH  = 64;
    parameter DMEM_DEPTH  = 256;
    parameter NUM_CYCLES  = 25;       // Ciclos a ejecutar

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  clk;
    reg  rst;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    rv32i_single_cycle #(
        .IMEM_DEPTH   (IMEM_DEPTH),
        .DMEM_DEPTH   (DMEM_DEPTH),
        .RESET_VECTOR (32'h0000_0000),
        .HEX_FILE     ("../../source/program.hex")
    ) dut (
        .clk (clk),
        .rst (rst)
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
    // Tarea auxiliar: verifica un registro del banco
    // --------------------------------------------------------
    task check_reg;
        input [4:0]  reg_addr;
        input [31:0] expected;
        begin
            if (dut.u_reg_file.registers[reg_addr] === expected) begin
                $display("[PASS] x%0d = 0x%08h", reg_addr, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] x%0d = 0x%08h (expected 0x%08h)",
                         reg_addr,
                         dut.u_reg_file.registers[reg_addr],
                         expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // Tarea auxiliar: verifica una posicion de memoria de datos
    // --------------------------------------------------------
    task check_mem;
        input [31:0] word_index;
        input [31:0] expected;
        begin
            if (dut.u_dmem.mem_array[word_index] === expected) begin
                $display("[PASS] MEM[%0d] = 0x%08h", word_index, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] MEM[%0d] = 0x%08h (expected 0x%08h)",
                         word_index,
                         dut.u_dmem.mem_array[word_index],
                         expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // Monitor: muestra PC y instruccion en cada ciclo
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            $display("  [cycle] PC=0x%08h  INSTR=0x%08h",
                     dut.pc_current, dut.instruction);
        end
    end

    // --------------------------------------------------------
    // Estimulos principales
    // --------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=========================================");
        $display(" Testbench: rv32i_single_cycle");
        $display(" Programa de prueba RV32I");
        $display("=========================================");

        // --- Reset ---
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;

        $display("\n--- Ejecutando programa (%0d ciclos) ---\n", NUM_CYCLES);

        // --- Ejecutar programa ---
        repeat (NUM_CYCLES) @(posedge clk);

        // --- Esperar un ciclo adicional para estabilizar ---
        #1;

        $display("\n--- Verificacion de registros ---\n");

        // ---- Programa ejecutado:
        // 0x00: ADDI x1, x0, 5       -> x1 = 5
        // 0x04: ADDI x2, x0, 10      -> x2 = 10
        // 0x08: ADD  x3, x1, x2      -> x3 = 15
        // 0x0C: SUB  x4, x1, x2      -> x4 = -5 (0xFFFFFFFB)
        // 0x10: AND  x5, x1, x2      -> x5 = 5 & 10 = 0
        // 0x14: OR   x6, x1, x2      -> x6 = 5 | 10 = 15
        // 0x18: SLT  x7, x1, x2      -> x7 = 1
        // 0x1C: SW   x3, 0(x0)       -> MEM[0] = 15
        // 0x20: LW   x8, 0(x0)       -> x8 = 15
        // 0x24: BEQ  x1, x1, +8      -> taken, skip 0x28
        // 0x28: ADDI x9, x0, 99      -> SKIPPED
        // 0x2C: LUI  x9, 0xDEADB     -> x9 = 0xDEADB000
        // 0x30: AUIPC x10, 1         -> x10 = 0x30 + 0x1000 = 0x1030
        // 0x34: JAL  x11, +8         -> x11 = 0x38, jump to 0x3C
        // 0x38: ADDI x12, x0, 77     -> SKIPPED
        // 0x3C: ADDI x12, x0, 42     -> x12 = 42
        // 0x40: JAL  x0, 0           -> loop infinito

        // --- Verificar registros ---
        check_reg(5'd1,  32'h0000_0005);    // x1 = 5
        check_reg(5'd2,  32'h0000_000A);    // x2 = 10
        check_reg(5'd3,  32'h0000_000F);    // x3 = 15
        check_reg(5'd4,  32'hFFFF_FFFB);    // x4 = -5
        check_reg(5'd5,  32'h0000_0000);    // x5 = 5 & 10 = 0
        check_reg(5'd6,  32'h0000_000F);    // x6 = 5 | 10 = 15
        check_reg(5'd7,  32'h0000_0001);    // x7 = 1 (SLT)
        check_reg(5'd8,  32'h0000_000F);    // x8 = 15 (LW)
        check_reg(5'd9,  32'hDEAD_B000);    // x9 = LUI 0xDEADB
        check_reg(5'd10, 32'h0000_1030);    // x10 = AUIPC (0x30 + 0x1000)
        check_reg(5'd11, 32'h0000_0038);    // x11 = JAL link (PC+4 = 0x38)
        check_reg(5'd12, 32'h0000_002A);    // x12 = 42

        // --- Verificar memoria ---
        $display("\n--- Verificacion de memoria ---\n");
        check_mem(0, 32'h0000_000F);        // MEM[0] = 15 (SW x3)

        // --- Verificar que x9 NO es 99 (BEQ skipped la instruccion) ---
        $display("\n--- Verificacion de branch (skip) ---\n");
        if (dut.u_reg_file.registers[9] !== 32'd99) begin
            $display("[PASS] x9 != 99 (BEQ correctly skipped ADDI x9, x0, 99)");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] x9 == 99 (BEQ did NOT skip!)");
            fail_count = fail_count + 1;
        end

        // --- Verificar que x12 NO es 77 (JAL skipped la instruccion) ---
        if (dut.u_reg_file.registers[12] !== 32'd77) begin
            $display("[PASS] x12 != 77 (JAL correctly skipped ADDI x12, x0, 77)");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] x12 == 77 (JAL did NOT skip!)");
            fail_count = fail_count + 1;
        end

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
