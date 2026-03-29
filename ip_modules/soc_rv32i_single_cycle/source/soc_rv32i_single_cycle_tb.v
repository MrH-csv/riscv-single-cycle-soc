// ============================================================
// Testbench — soc_rv32i_single_cycle
// Verifica el programa LED chaser con GPIO memory-mapped.
//
// El programa lee los switches (GPIO_IN = 0x10010028) para
// determinar cuantas veces recorrer los 8 LEDs.
// En cada iteracion interna, enciende un LED a la vez
// (bit walking: 1, 2, 4, 8, 16, 32, 64, 128).
// ============================================================

`timescale 1ns/1ps

module soc_rv32i_single_cycle_tb;

    // --------------------------------------------------------
    // Parametros
    // --------------------------------------------------------
    parameter CLK_PERIOD = 10;       // 100 MHz
    parameter IMEM_DEPTH = 64;
    parameter DMEM_DEPTH = 256;

    // --------------------------------------------------------
    // Senales
    // --------------------------------------------------------
    reg        clk;
    reg        rst;
    wire [7:0] gpio_out;
    reg  [7:0] gpio_in;

    // --------------------------------------------------------
    // Instanciacion del DUT
    // --------------------------------------------------------
    soc_rv32i_single_cycle #(
        .IMEM_DEPTH   (IMEM_DEPTH),
        .DMEM_DEPTH   (DMEM_DEPTH),
        .RESET_VECTOR (32'h0040_0000)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .o_gpio_out (gpio_out),
        .i_gpio_in  (gpio_in)
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
    integer cycle_count;

    // --------------------------------------------------------
    // Tarea auxiliar: verifica un registro del banco
    // --------------------------------------------------------
    task check_reg;
        input [4:0]  reg_addr;
        input [31:0] expected;
        begin
            if (dut.u_core.u_reg_file.registers[reg_addr] === expected) begin
                $display("[PASS] x%0d = 0x%08h", reg_addr, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] x%0d = 0x%08h (expected 0x%08h)",
                         reg_addr,
                         dut.u_core.u_reg_file.registers[reg_addr],
                         expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // Tarea auxiliar: verifica valor de gpio_out
    // --------------------------------------------------------
    task check_gpio_out;
        input [7:0] expected;
        begin
            if (gpio_out === expected) begin
                $display("[PASS] GPIO_OUT = 0x%02h", expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] GPIO_OUT = 0x%02h (expected 0x%02h)",
                         gpio_out, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --------------------------------------------------------
    // Monitor: muestra PC, instruccion y GPIO en cada ciclo
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;
            $display("  [%0d] PC=0x%08h  INSTR=0x%08h  GPIO_OUT=0x%02h",
                     cycle_count,
                     dut.u_core.o_imem_addr,
                     dut.imem_rdata,
                     gpio_out);
        end
    end

    // --------------------------------------------------------
    // Estimulos principales
    // --------------------------------------------------------
    initial begin
        pass_count  = 0;
        fail_count  = 0;
        cycle_count = 0;

        // --- Switches: 2 iteraciones del LED chaser ---
        gpio_in = 8'd2;

        $display("=========================================");
        $display(" Testbench: soc_rv32i_single_cycle");
        $display(" Programa: LED chaser (GPIO)");
        $display(" SW[7:0] = %0d (iteraciones)", gpio_in);
        $display("=========================================");

        // --- Reset ---
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;

        // =============================================================
        // Fase 1: Verificar setup de direcciones (ciclos 1-4)
        //   Ciclo 1: auipc s0, 0xFC10     -> s0 = 0x10010000
        //   Ciclo 2: addi  s1, s0, 0x24   -> s1 = 0x10010024
        //   Ciclo 3: addi  s2, s0, 0x28   -> s2 = 0x10010028
        //   Ciclo 4: lw    s5, 0(s2)      -> s5 = 2 (gpio_in)
        // =============================================================

        $display("\n--- Fase 1: Setup de direcciones ---\n");
        repeat (4) @(posedge clk);
        #1;

        check_reg(5'd8,  32'h1001_0000);    // s0 = base GPIO
        check_reg(5'd9,  32'h1001_0024);    // s1 = GPIO_OUT addr
        check_reg(5'd18, 32'h1001_0028);    // s2 = GPIO_IN addr
        check_reg(5'd21, 32'h0000_0002);    // s5 = 2 (switches)

        // =============================================================
        // Fase 2: Primera iteracion del LED chaser (8 LEDs)
        //   Cada iteracion interna: addi + addi + sw + slli + addi + bne
        //   sw escribe a GPIO_OUT el patron de LED actual
        // =============================================================

        $display("\n--- Fase 2: Primera iteracion LED chaser ---\n");

        // Ciclo 5: addi s3, zero, 1  -> s3 = 1
        // Ciclo 6: addi s4, zero, 8  -> s4 = 8
        repeat (2) @(posedge clk);
        #1;
        check_reg(5'd19, 32'h0000_0001);    // s3 = 1
        check_reg(5'd20, 32'h0000_0008);    // s4 = 8

        // LOOP_2 iteracion 1: sw + slli + addi + bne = 4 ciclos
        // Ciclo 7: sw s3, 0(s1)  -> GPIO_OUT = 0x01
        repeat (1) @(posedge clk);
        #1;
        check_gpio_out(8'h01);              // LED 0

        // Siguientes 7 iteraciones de LOOP_2 (4 ciclos cada una)
        // Iter 2: GPIO_OUT = 0x02
        repeat (4) @(posedge clk);
        #1;
        check_gpio_out(8'h02);              // LED 1

        // Iter 3: GPIO_OUT = 0x04
        repeat (4) @(posedge clk);
        #1;
        check_gpio_out(8'h04);              // LED 2

        // Iter 4: GPIO_OUT = 0x08
        repeat (4) @(posedge clk);
        #1;
        check_gpio_out(8'h08);              // LED 3

        // Iter 5: GPIO_OUT = 0x10
        repeat (4) @(posedge clk);
        #1;
        check_gpio_out(8'h10);              // LED 4

        // Iter 6: GPIO_OUT = 0x20
        repeat (4) @(posedge clk);
        #1;
        check_gpio_out(8'h20);              // LED 5

        // Iter 7: GPIO_OUT = 0x40
        repeat (4) @(posedge clk);
        #1;
        check_gpio_out(8'h40);              // LED 6

        // Iter 8: GPIO_OUT = 0x80
        repeat (4) @(posedge clk);
        #1;
        check_gpio_out(8'h80);              // LED 7

        // =============================================================
        // Fase 3: Fin de iteracion externa 1
        //   Despues del ultimo bne de LOOP_2 (not taken),
        //   se ejecuta: addi s5, s5, -1 ; bne s5, zero, LOOP_1
        //   s5 pasa de 2 a 1 -> branch taken, regresa a LOOP_1
        // =============================================================

        $display("\n--- Fase 3: Transicion a segunda iteracion ---\n");

        // addi s5, s5, -1 (bne no taken sale de LOOP_2) + bne s5,zero,LOOP_1
        // La ultima iteracion de LOOP_2: bne not taken = 1 ciclo
        // Luego: addi s5 + bne s5 (taken) = 2 ciclos
        // Luego LOOP_1: addi s3 + addi s4 = 2 ciclos
        // Luego LOOP_2: sw = primer write de segunda iteracion
        // Total desde ultimo check: ~3 ciclos hasta reinicio de LOOP_1
        repeat (3) @(posedge clk);
        #1;
        check_reg(5'd21, 32'h0000_0001);    // s5 = 1 (una iteracion restante)

        // =============================================================
        // Fase 4: Avanzar hasta EXIT y verificar estado final
        // =============================================================

        $display("\n--- Fase 4: Ejecutar hasta EXIT ---\n");

        // Segunda iteracion completa: 2 (setup) + 8*4 (loop2) + 2 (addi+bne) = ~36 ciclos
        repeat (40) @(posedge clk);
        #1;

        // s5 debe ser 0 (salio del loop externo)
        check_reg(5'd21, 32'h0000_0000);    // s5 = 0 (termino)

        // El ultimo LED encendido fue 0x80 (segunda iteracion tambien termina en LED 7)
        check_gpio_out(8'h80);              // Ultimo LED encendido

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
