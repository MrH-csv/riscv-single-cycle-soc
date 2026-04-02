/***********************************************************
 * Descripcion:
 *   Testbench del SoC completo con programa de factorial
 *   via UART. Envia un byte (n) por UART RX al SoC y
 *   verifica que los 4 bytes transmitidos por UART TX
 *   correspondan al factorial de n.
 *
 *   Caso de prueba: n = 5 -> 5! = 120 = 0x00000078
 *   Bytes esperados (MSB primero): 0x00, 0x00, 0x00, 0x78
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
 *   02/04/2026
 ***********************************************************/

`timescale 1ns/1ps

module soc_uart_factorial_tb;

    // ========================================================================
    // Parametros
    // ========================================================================
    localparam CLK_FREQ     = 50_000_000;
    localparam BAUD_RATE    = 9600;
    localparam CLK_PERIOD   = 20;           // 50 MHz -> 20 ns
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;  // 5208
    localparam BIT_PERIOD   = CLK_PERIOD * CLKS_PER_BIT;

    // ========================================================================
    // Senales del DUT
    // ========================================================================
    reg        clk;
    reg        rst;
    wire [7:0] gpio_out;
    reg  [7:0] gpio_in;
    wire       uart_tx_pin;
    reg        uart_rx_pin;

    // ========================================================================
    // Instancia del SoC
    // ========================================================================
    soc_rv32i_single_cycle #(
        .IMEM_DEPTH   (64),
        .DMEM_DEPTH   (256),
        .RESET_VECTOR (32'h0040_0000),
        .CLK_FREQ     (CLK_FREQ),
        .BAUD_RATE    (BAUD_RATE)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .o_gpio_out (gpio_out),
        .i_gpio_in  (gpio_in),
        .o_uart_tx  (uart_tx_pin),
        .i_uart_rx  (uart_rx_pin)
    );

    // ========================================================================
    // Generacion de reloj (50 MHz)
    // ========================================================================
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ========================================================================
    // Tarea: enviar un byte por UART al SoC (simula terminal serial)
    // ========================================================================
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            $display("[TB] Enviando byte: 0x%02h", data);
            // Bit de inicio
            uart_rx_pin = 1'b0;
            repeat (CLKS_PER_BIT) @(posedge clk);

            // 8 bits de datos (LSB primero)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_pin = data[i];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            // Bit de parada
            uart_rx_pin = 1'b1;
            repeat (CLKS_PER_BIT) @(posedge clk);

            $display("[TB] Byte enviado completamente");
        end
    endtask

    // ========================================================================
    // Tarea: recibir un byte desde el UART TX del SoC
    // ========================================================================
    task receive_byte;
        output [7:0] data;
        integer i;
        begin
            // Esperar bit de inicio (flanco de bajada)
            @(negedge uart_tx_pin);

            // Avanzar al centro del bit de inicio
            repeat (CLKS_PER_BIT / 2) @(posedge clk);

            // Muestrear 8 bits de datos
            for (i = 0; i < 8; i = i + 1) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                data[i] = uart_tx_pin;
            end

            // Esperar bit de parada
            repeat (CLKS_PER_BIT) @(posedge clk);

            $display("[TB] Byte recibido: 0x%02h", data);
        end
    endtask

    // ========================================================================
    // Secuencia principal de prueba
    // ========================================================================
    reg [7:0] rx_byte_3, rx_byte_2, rx_byte_1, rx_byte_0;
    reg [31:0] received_result;
    reg [7:0]  test_n;
    reg [31:0] expected_factorial;
    integer errors;

    initial begin
        // --- Inicializacion ---
        rst         = 1'b1;
        uart_rx_pin = 1'b1;    // UART idle = alto
        gpio_in     = 8'h00;
        errors      = 0;

        // --- Reset ---
        repeat (10) @(posedge clk);
        rst = 1'b0;
        $display("[TB] Reset liberado");

        // Esperar a que el procesador inicialice (instrucciones 0-3)
        repeat (10) @(posedge clk);

        // ==============================================================
        // Test 1: factorial(5) = 120 = 0x00000078
        // ==============================================================
        test_n             = 8'd5;
        expected_factorial = 32'h00000078;
        $display("\n[TB] === TEST 1: factorial(%0d) ===", test_n);

        send_byte(test_n);

        // Recibir 4 bytes de respuesta (MSB primero)
        receive_byte(rx_byte_3);
        receive_byte(rx_byte_2);
        receive_byte(rx_byte_1);
        receive_byte(rx_byte_0);

        received_result = {rx_byte_3, rx_byte_2, rx_byte_1, rx_byte_0};
        $display("[TB] Resultado recibido:  0x%08h", received_result);
        $display("[TB] Resultado esperado:  0x%08h", expected_factorial);

        if (received_result == expected_factorial) begin
            $display("[TB] TEST 1 PASSED: %0d! = %0d", test_n, received_result);
        end else begin
            $display("[TB] TEST 1 FAILED!");
            errors = errors + 1;
        end

        // ==============================================================
        // Test 2: factorial(1) = 1 = 0x00000001
        // ==============================================================
        test_n             = 8'd1;
        expected_factorial = 32'h00000001;
        $display("\n[TB] === TEST 2: factorial(%0d) ===", test_n);

        // Esperar un poco para que el procesador vuelva a WAIT_RX
        repeat (20) @(posedge clk);

        send_byte(test_n);

        receive_byte(rx_byte_3);
        receive_byte(rx_byte_2);
        receive_byte(rx_byte_1);
        receive_byte(rx_byte_0);

        received_result = {rx_byte_3, rx_byte_2, rx_byte_1, rx_byte_0};
        $display("[TB] Resultado recibido:  0x%08h", received_result);
        $display("[TB] Resultado esperado:  0x%08h", expected_factorial);

        if (received_result == expected_factorial) begin
            $display("[TB] TEST 2 PASSED: %0d! = %0d", test_n, received_result);
        end else begin
            $display("[TB] TEST 2 FAILED!");
            errors = errors + 1;
        end

        // ==============================================================
        // Test 3: factorial(10) = 3628800 = 0x00375F00
        // ==============================================================
        test_n             = 8'd10;
        expected_factorial = 32'h00375F00;
        $display("\n[TB] === TEST 3: factorial(%0d) ===", test_n);

        repeat (20) @(posedge clk);

        send_byte(test_n);

        receive_byte(rx_byte_3);
        receive_byte(rx_byte_2);
        receive_byte(rx_byte_1);
        receive_byte(rx_byte_0);

        received_result = {rx_byte_3, rx_byte_2, rx_byte_1, rx_byte_0};
        $display("[TB] Resultado recibido:  0x%08h", received_result);
        $display("[TB] Resultado esperado:  0x%08h", expected_factorial);

        if (received_result == expected_factorial) begin
            $display("[TB] TEST 3 PASSED: %0d! = %0d", test_n, received_result);
        end else begin
            $display("[TB] TEST 3 FAILED!");
            errors = errors + 1;
        end

        // ==============================================================
        // Resumen
        // ==============================================================
        $display("\n========================================");
        if (errors == 0)
            $display("  TODOS LOS TESTS PASARON (%0d/3)", 3);
        else
            $display("  %0d TEST(S) FALLARON de 3", errors);
        $display("========================================\n");

        #(BIT_PERIOD * 2);
        $finish;
    end

    // ========================================================================
    // Timeout de seguridad (30 ms = suficiente para 3 tests)
    // ========================================================================
    initial begin
        #(30_000_000);
        $display("[TB] ERROR: Timeout alcanzado!");
        $finish;
    end

endmodule
