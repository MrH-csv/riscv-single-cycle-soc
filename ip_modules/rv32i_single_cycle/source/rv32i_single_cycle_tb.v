// ============================================================
// Testbench — rv32i_single_cycle (core standalone)
// Conecta ROM y RAM directamente al core para verificar
// el datapath de forma aislada, sin el SoC.
// ============================================================

`timescale 1ns/1ps

module rv32i_single_cycle_tb;

    // --------------------------------------------------------
    // Parametros
    // --------------------------------------------------------
    parameter CLK_PERIOD  = 10;       // 100 MHz
    parameter IMEM_DEPTH  = 64;
    parameter DMEM_DEPTH  = 256;
    parameter NUM_CYCLES  = 25;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  clk;
    reg  rst;

    // Bus de instrucciones
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    // Bus de datos
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire        dmem_we;
    wire        dmem_re;
    wire [31:0] dmem_rdata;

    // --------------------------------------------------------
    // Instanciacion del DUT (core)
    // --------------------------------------------------------
    rv32i_single_cycle #(
        .RESET_VECTOR (32'h0000_0000)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .o_imem_addr  (imem_addr),
        .i_imem_rdata (imem_rdata),
        .o_dmem_addr  (dmem_addr),
        .o_dmem_wdata (dmem_wdata),
        .o_dmem_we    (dmem_we),
        .o_dmem_re    (dmem_re),
        .i_dmem_rdata (dmem_rdata)
    );

    // --------------------------------------------------------
    // Memorias locales para el test
    // --------------------------------------------------------
    rom_combinational_sc #(
        .DEPTH    (IMEM_DEPTH),
        .HEX_FILE ("../../source/program.hex")
    ) u_imem (
        .i_pc_addr     (imem_addr),
        .o_instruction (imem_rdata)
    );

    data_memory #(
        .DEPTH (DMEM_DEPTH)
    ) u_dmem (
        .clk         (clk),
        .i_mem_write (dmem_we),
        .i_mem_read  (dmem_re),
        .i_addr      (dmem_addr),
        .i_wdata     (dmem_wdata),
        .o_rdata     (dmem_rdata)
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
            if (u_dmem.mem_array[word_index] === expected) begin
                $display("[PASS] MEM[%0d] = 0x%08h", word_index, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] MEM[%0d] = 0x%08h (expected 0x%08h)",
                         word_index,
                         u_dmem.mem_array[word_index],
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
                     imem_addr, imem_rdata);
        end
    end

    // --------------------------------------------------------
    // Estimulos principales
    // --------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=========================================");
        $display(" Testbench: rv32i_single_cycle (core)");
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

        // --- Verificar que x9 NO es 99 (BEQ skipped) ---
        $display("\n--- Verificacion de branch (skip) ---\n");
        if (dut.u_reg_file.registers[9] !== 32'd99) begin
            $display("[PASS] x9 != 99 (BEQ correctly skipped ADDI x9, x0, 99)");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] x9 == 99 (BEQ did NOT skip!)");
            fail_count = fail_count + 1;
        end

        // --- Verificar que x12 NO es 77 (JAL skipped) ---
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
