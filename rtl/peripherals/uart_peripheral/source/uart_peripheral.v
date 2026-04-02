/***********************************************************
 * Descripcion:
 *   Periferico UART memory-mapped para el SoC RV32I.
 *   Integra los modulos uart_tx y uart_rx con una
 *   interfaz de bus compatible con el decodificador de
 *   direcciones del SoC.
 *
 *   Mapa de registros (offsets dentro del espacio 0x1001xxxx):
 *     0x30  UART_TX_DATA  (W)   - Dato a transmitir [7:0]
 *     0x34  UART_RX_DATA  (R)   - Dato recibido [7:0]
 *                                  (lectura limpia rx_ready)
 *     0x38  UART_STATUS   (R)   - bit 0: tx_busy
 *                                  bit 1: rx_ready
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

module uart_peripheral #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk,
    input  wire        rst,

    // --- Interfaz de bus ---
    input  wire        i_cs,            // Chip select
    input  wire        i_we,            // Write enable
    input  wire [7:0]  i_addr,          // Offset de registro
    input  wire [31:0] i_wdata,         // Dato de escritura
    output reg  [31:0] o_rdata,         // Dato de lectura

    // --- Pines fisicos ---
    output wire        o_uart_tx,       // Linea serial TX
    input  wire        i_uart_rx        // Linea serial RX
);

    // ========================================================================
    // Offsets de registros
    // ========================================================================
    localparam OFFSET_TX_DATA = 8'h30;
    localparam OFFSET_RX_DATA = 8'h34;
    localparam OFFSET_STATUS  = 8'h38;

    // ========================================================================
    // Senales internas UART TX
    // ========================================================================
    wire       tx_busy;
    reg        tx_start;
    reg  [7:0] tx_data;

    // ========================================================================
    // Senales internas UART RX
    // ========================================================================
    wire [7:0] rx_data;
    wire       rx_valid;
    reg        rx_ready;        // Flag: dato disponible para lectura
    reg  [7:0] rx_data_reg;     // Dato recibido almacenado

    // ========================================================================
    // Generacion del pulso de inicio TX (escritura sincrona)
    // ========================================================================
    always @(posedge clk) begin
        if (rst) begin
            tx_start <= 1'b0;
            tx_data  <= 8'b0;
        end else begin
            tx_start <= 1'b0;
            if (i_cs && i_we && i_addr == OFFSET_TX_DATA && !tx_busy) begin
                tx_data  <= i_wdata[7:0];
                tx_start <= 1'b1;
            end
        end
    end

    // ========================================================================
    // Latch de dato recibido y bandera rx_ready
    // ========================================================================
    always @(posedge clk) begin
        if (rst) begin
            rx_ready    <= 1'b0;
            rx_data_reg <= 8'b0;
        end else begin
            if (rx_valid) begin
                rx_data_reg <= rx_data;
                rx_ready    <= 1'b1;
            end else if (i_cs && !i_we && i_addr == OFFSET_RX_DATA) begin
                rx_ready <= 1'b0;   // Limpia al leer RX_DATA
            end
        end
    end

    // ========================================================================
    // Lectura combinacional
    // ========================================================================
    always @(*) begin
        if (i_cs) begin
            case (i_addr)
                OFFSET_TX_DATA: o_rdata = 32'b0;
                OFFSET_RX_DATA: o_rdata = {24'b0, rx_data_reg};
                OFFSET_STATUS:  o_rdata = {30'b0, rx_ready, tx_busy};
                default:        o_rdata = 32'b0;
            endcase
        end else begin
            o_rdata = 32'b0;
        end
    end

    // ========================================================================
    // Instancia del transmisor UART
    // ========================================================================
    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_tx (
        .clk     (clk),
        .rst     (rst),
        .i_data  (tx_data),
        .i_start (tx_start),
        .o_tx    (o_uart_tx),
        .o_busy  (tx_busy)
    );

    // ========================================================================
    // Instancia del receptor UART
    // ========================================================================
    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_rx (
        .clk     (clk),
        .rst     (rst),
        .i_rx    (i_uart_rx),
        .o_data  (rx_data),
        .o_valid (rx_valid)
    );

endmodule
