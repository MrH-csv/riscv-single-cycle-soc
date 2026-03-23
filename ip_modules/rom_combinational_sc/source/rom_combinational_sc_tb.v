// ============================================================
// Testbench — rom_combinational_sc
// Verifica lectura combinacional de la ROM de instrucciones.
// No hay reloj: se aplican direcciones y se espera un
// retardo de propagación antes de verificar la salida.
// ============================================================

`timescale 1ns/1ps

module rom_combinational_sc_tb;

    // --------------------------------------------------------
    // Señales
    // --------------------------------------------------------
    reg  [31:0] i_pc_addr;
    wire [31:0] o_instruction;

    // --------------------------------------------------------
    // Instanciación del DUT
    // --------------------------------------------------------
    rom_combinational_sc #(
        .DEPTH    (64),
        .HEX_FILE ("../../source/program.hex")
    ) dut (
        .i_pc_addr    (i_pc_addr),
        .o_instruction(o_instruction)
    );

    // --------------------------------------------------------
    // Valores esperados (deben coincidir con program.hex)
    // --------------------------------------------------------
    localparam [31:0] EXP_NOP      = 32'h00000013;  // PC 0x00
    localparam [31:0] EXP_ADDI_X1  = 32'h00100093;  // PC 0x04
    localparam [31:0] EXP_ADDI_X2  = 32'h00200113;  // PC 0x08
    localparam [31:0] EXP_ADD_X3   = 32'h002081b3;  // PC 0x0C
    localparam [31:0] EXP_JAL      = 32'h0000006f;  // PC 0x10

    // --------------------------------------------------------
    // Contadores de resultado
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Tarea auxiliar: verificar una lectura
    // --------------------------------------------------------
    task check;
        input [31:0] addr;
        input [31:0] expected;
        begin
            i_pc_addr = addr;
            #10;  // retardo de propagación combinacional
            if (o_instruction === expected) begin
                $display("[PASS] PC=0x%08h  ->  instr=0x%08h", addr, o_instruction);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] PC=0x%08h  ->  instr=0x%08h  (esperado 0x%08h)",
                         addr, o_instruction, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // Estímulos
    // --------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;
        i_pc_addr  = 32'd0;

        $display("=========================================");
        $display(" Testbench: rom_combinational_sc");
        $display("=========================================");

        // Lectura secuencial de las 5 instrucciones reales
        check(32'h00000000, EXP_NOP);
        check(32'h00000004, EXP_ADDI_X1);
        check(32'h00000008, EXP_ADDI_X2);
        check(32'h0000000C, EXP_ADD_X3);
        check(32'h00000010, EXP_JAL);

        // Lectura de zona de relleno (NOPs)
        check(32'h00000014, EXP_NOP);
        check(32'h0000003C, EXP_NOP);
        check(32'h000000FC, EXP_NOP);  // última palabra (índice 63)

        // Lectura no secuencial (saltos)
        check(32'h0000000C, EXP_ADD_X3);
        check(32'h00000000, EXP_NOP);
        check(32'h00000010, EXP_JAL);
        check(32'h00000004, EXP_ADDI_X1);

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
