/***********************************************************
 * Descripcion:
 *   Periferico GPIO memory-mapped para el SoC RV32I.
 *   Provee un registro de salida de 8 bits (LEDs) y un
 *   registro de entrada de 8 bits (switches) de la
 *   tarjeta DE10-Standard (Cyclone V 5CSXFC6D6F31C6N).
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
 *   29/03/2026
 ***********************************************************/

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

    // --- Pines fisicos ---
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
