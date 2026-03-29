// ============================================================
// Testbench — main_control_rv32i
// Verifica decodificacion del opcode para todas las senales
// de control del datapath RV32I single-cycle.
// Cubre los 7 tipos de instruccion: R, I, Load, Store,
// Branch, LUI, AUIPC, JAL, JALR.
// ============================================================

`timescale 1ns/1ps

module main_control_rv32i_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [6:0] i_opcode;
    wire       o_reg_write;
    wire [1:0] o_result_src;
    wire       o_mem_write;
    wire       o_mem_read;
    wire       o_branch;
    wire       o_jump;
    wire       o_jalr;
    wire [1:0] o_alu_op;
    wire       o_alu_src;
    wire       o_alu_a_src;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    main_control_rv32i dut (
        .i_opcode   (i_opcode),
        .o_reg_write(o_reg_write),
        .o_result_src(o_result_src),
        .o_mem_write(o_mem_write),
        .o_mem_read (o_mem_read),
        .o_branch   (o_branch),
        .o_jump     (o_jump),
        .o_jalr     (o_jalr),
        .o_alu_op   (o_alu_op),
        .o_alu_src  (o_alu_src),
        .o_alu_a_src(o_alu_a_src)
    );

    // --------------------------------------------------------
    // Contadores de resultado
    // --------------------------------------------------------
    integer pass_count;
    integer fail_count;

    // --------------------------------------------------------
    // Tarea auxiliar: verifica TODAS las salidas de una vez
    // --------------------------------------------------------
    task check;
        input [6:0]  opcode;
        input        exp_reg_write;
        input [1:0]  exp_result_src;
        input        exp_mem_write;
        input        exp_mem_read;
        input        exp_branch;
        input        exp_jump;
        input        exp_jalr;
        input [1:0]  exp_alu_op;
        input        exp_alu_src;
        input        exp_alu_a_src;
        begin
            i_opcode = opcode;
            #10;
            if (o_reg_write  === exp_reg_write  &&
                o_result_src === exp_result_src  &&
                o_mem_write  === exp_mem_write   &&
                o_mem_read   === exp_mem_read    &&
                o_branch     === exp_branch      &&
                o_jump       === exp_jump        &&
                o_jalr       === exp_jalr        &&
                o_alu_op     === exp_alu_op      &&
                o_alu_src    === exp_alu_src     &&
                o_alu_a_src  === exp_alu_a_src) begin
                $display("[PASS] opcode=%b -> rw=%b rs=%b mw=%b mr=%b br=%b jmp=%b jalr=%b aop=%b as=%b aas=%b",
                         opcode, o_reg_write, o_result_src, o_mem_write, o_mem_read,
                         o_branch, o_jump, o_jalr, o_alu_op, o_alu_src, o_alu_a_src);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] opcode=%b", opcode);
                $display("       GOT:  rw=%b rs=%b mw=%b mr=%b br=%b jmp=%b jalr=%b aop=%b as=%b aas=%b",
                         o_reg_write, o_result_src, o_mem_write, o_mem_read,
                         o_branch, o_jump, o_jalr, o_alu_op, o_alu_src, o_alu_a_src);
                $display("       EXP:  rw=%b rs=%b mw=%b mr=%b br=%b jmp=%b jalr=%b aop=%b as=%b aas=%b",
                         exp_reg_write, exp_result_src, exp_mem_write, exp_mem_read,
                         exp_branch, exp_jump, exp_jalr, exp_alu_op, exp_alu_src, exp_alu_a_src);
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
        $display(" Testbench: main_control_rv32i");
        $display("=========================================");

        //              opcode     rw  rsrc  mw mr br jmp jalr aop  as aas
        // R-type (0110011)
        check(7'b0110011, 1, 2'b00, 0, 0, 0, 0, 0, 2'b10, 0, 0);

        // I-ALU (0010011)
        check(7'b0010011, 1, 2'b00, 0, 0, 0, 0, 0, 2'b10, 1, 0);

        // Load (0000011)
        check(7'b0000011, 1, 2'b01, 0, 1, 0, 0, 0, 2'b00, 1, 0);

        // Store (0100011)
        check(7'b0100011, 0, 2'b00, 1, 0, 0, 0, 0, 2'b00, 1, 0);

        // Branch (1100011)
        check(7'b1100011, 0, 2'b00, 0, 0, 1, 0, 0, 2'b01, 0, 0);

        // LUI (0110111)
        check(7'b0110111, 1, 2'b11, 0, 0, 0, 0, 0, 2'b00, 0, 0);

        // AUIPC (0010111)
        check(7'b0010111, 1, 2'b00, 0, 0, 0, 0, 0, 2'b00, 1, 1);

        // JAL (1101111)
        check(7'b1101111, 1, 2'b10, 0, 0, 0, 1, 0, 2'b00, 0, 0);

        // JALR (1100111)
        check(7'b1100111, 1, 2'b10, 0, 0, 0, 1, 1, 2'b00, 1, 0);

        // Opcode invalido -> todo a 0
        check(7'b1111111, 0, 2'b00, 0, 0, 0, 0, 0, 2'b00, 0, 0);
        check(7'b0000000, 0, 2'b00, 0, 0, 0, 0, 0, 2'b00, 0, 0);

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
