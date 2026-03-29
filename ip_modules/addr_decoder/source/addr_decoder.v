// ============================================================================
// Module:      addr_decoder
// Description: Decodificador de direcciones para el bus de datos del SoC.
//              Genera senales chip-select segun los bits altos de la direccion
//              y multiplexa el dato de lectura de vuelta al core.
//
// Mapa de memoria:
//   0x0000_0000 – 0x0FFF_FFFF : Data RAM   (cs_dmem)
//   0x1001_0000 – 0x1001_FFFF : GPIO       (cs_gpio)
//     0x1001_0024 : GPIO_OUT (8 bits, R/W)
//     0x1001_0028 : GPIO_IN  (8 bits, R)
//
// Port map:
//   i_addr       [31:0] — Direccion del bus de datos (desde el core)
//   i_mem_we             — Write enable global (desde el core)
//   i_mem_re             — Read enable global (desde el core)
//   o_cs_dmem            — Chip select para Data RAM
//   o_cs_gpio            — Chip select para GPIO
//   i_dmem_rdata [31:0] — Dato leido de la RAM
//   i_gpio_rdata [31:0] — Dato leido del GPIO
//   o_rdata      [31:0] — Dato de lectura multiplexado hacia el core
// ============================================================================

`timescale 1ns/1ps

module addr_decoder (
    // --- Bus del core ---
    input  wire [31:0] i_addr,
    input  wire        i_mem_we,
    input  wire        i_mem_re,

    // --- Chip selects ---
    output wire        o_cs_dmem,
    output wire        o_cs_gpio,

    // --- Datos de lectura de cada periferico ---
    input  wire [31:0] i_dmem_rdata,
    input  wire [31:0] i_gpio_rdata,

    // --- Dato de lectura multiplexado al core ---
    output reg  [31:0] o_rdata
);

    // ========================================================================
    // Decodificacion de direccion
    // ========================================================================

    wire is_gpio = (i_addr[31:16] == 16'h1001);
    wire is_dmem = ~is_gpio;

    assign o_cs_dmem = is_dmem & (i_mem_we | i_mem_re);
    assign o_cs_gpio = is_gpio & (i_mem_we | i_mem_re);

    // ========================================================================
    // MUX de lectura
    // ========================================================================

    always @(*) begin
        case (1'b1)
            is_gpio: o_rdata = i_gpio_rdata;
            default: o_rdata = i_dmem_rdata;
        endcase
    end

endmodule
