// ============================================================================
// Module:      gpio_peripheral
// Description: Periferico GPIO memory-mapped para el SoC RV32I.
//              Provee un registro de salida de 8 bits (LEDs) y un registro
//              de entrada de 8 bits (switches) de la tarjeta DE2-115.
//
// Mapa de registros (direcciones absolutas):
//   0x1001_0024 : GPIO_OUT [7:0] — Registro de salida (R/W) → LEDs LEDR[7:0]
//   0x1001_0028 : GPIO_IN  [7:0] — Entrada directa   (R)   → Switches SW[7:0]
//
// Port map:
//   clk, rst              — Reloj y reset sincrono
//   i_cs                  — Chip select (desde addr_decoder)
//   i_we                  — Write enable (desde el core)
//   i_addr        [7:0]   — Offset local (bits bajos de la direccion)
//   i_wdata      [31:0]   — Dato a escribir (desde el core)
//   o_rdata      [31:0]   — Dato leido (hacia el addr_decoder)
//   o_gpio_out    [7:0]   — Pines de salida → LEDs LEDR[7:0]
//   i_gpio_in     [7:0]   — Pines de entrada → Switches SW[7:0]
// ============================================================================

`timescale 1ns/1ps

module gpio_peripheral (
    input  wire        clk,
    input  wire        rst,

    // --- Interfaz de bus ---
    input  wire        i_cs,
    input  wire        i_we,
    input  wire [7:0]  i_addr,
    input  wire [31:0] i_wdata,
    output reg  [31:0] o_rdata,

    // --- Pines fisicos (DE2-115) ---
    output wire [7:0]  o_gpio_out,     // LEDs  LEDR[7:0]
    input  wire [7:0]  i_gpio_in       // Switches SW[7:0]
);

    // ========================================================================
    // Offsets de registros
    // ========================================================================
    localparam OFFSET_GPIO_OUT = 8'h24;
    localparam OFFSET_GPIO_IN  = 8'h28;

    // ========================================================================
    // Registro de salida (8 bits)
    // ========================================================================

    reg [7:0] gpio_out_reg;

    assign o_gpio_out = gpio_out_reg;

    // --- Escritura sincrona ---
    always @(posedge clk) begin
        if (rst)
            gpio_out_reg <= 8'b0;
        else if (i_cs && i_we && i_addr == OFFSET_GPIO_OUT)
            gpio_out_reg <= i_wdata[7:0];
    end

    // ========================================================================
    // Lectura combinacional
    // ========================================================================

    always @(*) begin
        if (i_cs) begin
            case (i_addr)
                OFFSET_GPIO_OUT: o_rdata = {24'b0, gpio_out_reg};
                OFFSET_GPIO_IN:  o_rdata = {24'b0, i_gpio_in};
                default:         o_rdata = 32'b0;
            endcase
        end else begin
            o_rdata = 32'b0;
        end
    end

endmodule
