/***********************************************************
 * Descripcion:
 *   SoC top-level que integra el core RV32I con memorias
 *   y perifericos memory-mapped para la tarjeta
 *   DE10-Standard (Cyclone V 5CSXFC6D6F31C6N).
 *   Incluye GPIO (LEDs/Switches) y UART (9600 baudios).
 *
 *   Tarjeta: DE10-Standard
 *   Asignacion de pines:
 *     clk        -> CLOCK_50 -> PIN_AF14
 *     rst        -> SW[9]    -> PIN_AA30
 *     o_uart_tx  -> GPIO_0[0]-> PIN_W15
 *     i_uart_rx  -> GPIO_0[1]-> PIN_AK2
 * Version:
 *   1.1
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

module soc_rv32i_single_cycle #(
    parameter IMEM_DEPTH   = 64,
    parameter DMEM_DEPTH   = 256,
    parameter RESET_VECTOR = 32'h0040_0000,
    parameter HEX_FILE     = "program.hex",
    parameter CLK_FREQ     = 50_000_000,
    parameter BAUD_RATE    = 9600
)(
    input  wire       clk,
    input  wire       rst,

    // --- GPIO pines fisicos ---
    output wire [7:0] o_gpio_out,      // LEDs  LEDR[7:0]
    input  wire [7:0] i_gpio_in,       // Switches SW[7:0]

    // --- UART pines fisicos ---
    output wire       o_uart_tx,       // TX -> PIN_W15
    input  wire       i_uart_rx        // RX -> PIN_AK2
);

    // ========================================================================
    // Buses del core
    // ========================================================================

    // --- Bus de instrucciones ---
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;

    // --- Bus de datos (core -> bus) ---
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire        dmem_we;
    wire        dmem_re;
    wire [31:0] dmem_rdata;

    // --- Chip selects ---
    wire cs_dmem;
    wire cs_gpio;
    wire cs_uart;

    // --- Datos de lectura por periferico ---
    wire [31:0] ram_rdata;
    wire [31:0] gpio_rdata;
    wire [31:0] uart_rdata;

    // ========================================================================
    // Core RV32I
    // ========================================================================

    rv32i_single_cycle #(
        .RESET_VECTOR (RESET_VECTOR)
    ) u_core (
        .clk          (clk),
        .rst          (rst),
        // Bus de instrucciones
        .o_imem_addr  (imem_addr),
        .i_imem_rdata (imem_rdata),
        // Bus de datos
        .o_dmem_addr  (dmem_addr),
        .o_dmem_wdata (dmem_wdata),
        .o_dmem_we    (dmem_we),
        .o_dmem_re    (dmem_re),
        .i_dmem_rdata (dmem_rdata)
    );

    // ========================================================================
    // Instruction Memory (ROM)
    // ========================================================================

    rom_combinational_sc #(
        .DEPTH    (IMEM_DEPTH),
        .HEX_FILE (HEX_FILE)
    ) u_imem (
        .i_pc_addr     (imem_addr),
        .o_instruction (imem_rdata)
    );

    // ========================================================================
    // Address Decoder
    // ========================================================================

    addr_decoder u_addr_dec (
        // Bus del core
        .i_addr       (dmem_addr),
        .i_mem_we     (dmem_we),
        .i_mem_re     (dmem_re),
        // Chip selects
        .o_cs_dmem    (cs_dmem),
        .o_cs_gpio    (cs_gpio),
        .o_cs_uart    (cs_uart),
        // Datos de lectura de cada periferico
        .i_dmem_rdata (ram_rdata),
        .i_gpio_rdata (gpio_rdata),
        .i_uart_rdata (uart_rdata),
        // Dato multiplexado al core
        .o_rdata      (dmem_rdata)
    );

    // ========================================================================
    // Data Memory (RAM)
    // ========================================================================

    data_memory #(
        .DEPTH (DMEM_DEPTH)
    ) u_dmem (
        .clk         (clk),
        .i_mem_write (cs_dmem & dmem_we),
        .i_mem_read  (cs_dmem & dmem_re),
        .i_addr      (dmem_addr),
        .i_wdata     (dmem_wdata),
        .o_rdata     (ram_rdata)
    );

    // ========================================================================
    // GPIO Peripheral
    // ========================================================================

    gpio_peripheral u_gpio (
        .clk        (clk),
        .rst        (rst),
        // Interfaz de bus
        .i_cs       (cs_gpio),
        .i_we       (dmem_we),
        .i_addr     (dmem_addr[7:0]),
        .i_wdata    (dmem_wdata),
        .o_rdata    (gpio_rdata),
        // Pines fisicos
        .o_gpio_out (o_gpio_out),
        .i_gpio_in  (i_gpio_in)
    );

    // ========================================================================
    // UART Peripheral
    // ========================================================================

    uart_peripheral #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_uart (
        .clk        (clk),
        .rst        (rst),
        // Interfaz de bus
        .i_cs       (cs_uart),
        .i_we       (dmem_we),
        .i_addr     (dmem_addr[7:0]),
        .i_wdata    (dmem_wdata),
        .o_rdata    (uart_rdata),
        // Pines fisicos
        .o_uart_tx  (o_uart_tx),
        .i_uart_rx  (i_uart_rx)
    );

endmodule
