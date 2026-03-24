// ============================================================
// Testbench — main_control_rv32i
// Verifica decodificacion del opcode para todas las senales
// de control del datapath RV32I single-cycle.
// ============================================================

`timescale 1ns/1ps

module main_control_rv32i_tb;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg  [6:0] i_opcode;
    wire       o_branch;
    wire       o_mem_read;
    wire       o_memto_reg;
    wire [1:0] o_alu_op;
    wire       o_mem_write;
    wire       o_alu_src;
    wire       o_reg_write;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    main_control_rv32i dut (
        .i_opcode  (i_opcode),
        .o_branch  (o_branch),
        .o_mem_read(o_mem_read),
        .o_memto_reg(o_memto_reg),
        .o_alu_op  (o_alu_op),
        .o_mem_write(o_mem_write),
        .o_alu_src (o_alu_src),
        .o_reg_write(o_reg_write)
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
        input        exp_branch;
        input        exp_mem_read;
        input        exp_memto_reg;
        input [1:0]  exp_alu_op;
        input        exp_mem_write;
        input        exp_alu_src;
        input        exp_reg_write;
        begin
            i_opcode = opcode;
            #10;
            if (o_branch    === exp_branch    &&
                o_mem_read  === exp_mem_read  &&
                o_memto_reg === exp_memto_reg &&
                o_alu_op    === exp_alu_op    &&
                o_mem_write === exp_mem_write &&
                o_alu_src   === exp_alu_src   &&
                o_reg_write === exp_reg_write) begin
                $display("[PASS] opcode=%b -> br=%b mr=%b m2r=%b aop=%b mw=%b as=%b rw=%b",
                         opcode, o_branch, o_mem_read, o_memto_reg, o_alu_op,
                         o_mem_write, o_alu_src, o_reg_write);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] opcode=%b", opcode);
                $display("       GOT:  br=%b mr=%b m2r=%b aop=%b mw=%b as=%b rw=%b",
                         o_branch, o_mem_read, o_memto_reg, o_alu_op,
                         o_mem_write, o_alu_src, o_reg_write);
                $display("       EXP:  br=%b mr=%b m2r=%b aop=%b mw=%b as=%b rw=%b",
                         exp_branch, exp_mem_read, exp_memto_reg, exp_alu_op,
                         exp_mem_write, exp_alu_src, exp_reg_write);
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

        //                opcode     br mr m2r aop  mw as rw
        // R-type (0110011)
        check(7'b0110011,  0, 0, 0, 2'b10, 0, 0, 1);

        // I-ALU (0010011)
        check(7'b0010011,  0, 0, 0, 2'b10, 0, 1, 1);

        // Load (0000011)
        check(7'b0000011,  0, 1, 1, 2'b00, 0, 1, 1);

        // Store (0100011)
        check(7'b0100011,  0, 0, 0, 2'b00, 1, 1, 0);

        // Branch (1100011)
        check(7'b1100011,  1, 0, 0, 2'b01, 0, 0, 0);

        // Opcode invalido -> todo a 0
        check(7'b1111111,  0, 0, 0, 2'b00, 0, 0, 0);
        check(7'b0000000,  0, 0, 0, 2'b00, 0, 0, 0);

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
