/***********************************************************
 * Descripcion:
 *   Receptor UART (Universal Asynchronous Receiver
 *   Transmitter). Implementacion comportamental con
 *   maquina de estados y sincronizador de doble flip-flop
 *   para evitar metaestabilidad. Formato: 1 start, 8 data
 *   (LSB primero), 1 stop, sin paridad. El muestreo se
 *   realiza en el centro de cada bit.
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

module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,   // Frecuencia del reloj (Hz)
    parameter BAUD_RATE = 9600           // Velocidad de recepcion (baudios)
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       i_rx,             // Linea serial RX
    output reg  [7:0] o_data,           // Dato recibido
    output reg        o_valid           // Pulso de 1 ciclo: dato valido
);

    // ========================================================================
    // Parametros de temporizacion
    // ========================================================================
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // ========================================================================
    // Estados de la maquina
    // ========================================================================
    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_DATA  = 2'b10;
    localparam S_STOP  = 2'b11;

    // ========================================================================
    // Registros internos
    // ========================================================================
    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  data_reg;

    // ========================================================================
    // Sincronizador de doble flip-flop (anti-metaestabilidad)
    // ========================================================================
    reg rx_sync_0, rx_sync_1;

    always @(posedge clk) begin
        if (rst) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end else begin
            rx_sync_0 <= i_rx;
            rx_sync_1 <= rx_sync_0;
        end
    end

    // ========================================================================
    // Maquina de estados del receptor
    // ========================================================================
    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            clk_cnt  <= 16'b0;
            bit_idx  <= 3'b0;
            data_reg <= 8'b0;
            o_data   <= 8'b0;
            o_valid  <= 1'b0;
        end else begin
            o_valid <= 1'b0;    // pulso de un solo ciclo

            case (state)
                // ----------------------------------------------------------
                // IDLE: espera flanco de bajada (bit de inicio)
                // ----------------------------------------------------------
                S_IDLE: begin
                    clk_cnt <= 16'b0;
                    if (rx_sync_1 == 1'b0) begin
                        state <= S_START;
                    end
                end

                // ----------------------------------------------------------
                // START: avanza al centro del bit de inicio para verificar
                // ----------------------------------------------------------
                S_START: begin
                    if (clk_cnt == (CLKS_PER_BIT / 2) - 1) begin
                        if (rx_sync_1 == 1'b0) begin
                            clk_cnt <= 16'b0;
                            bit_idx <= 3'b0;
                            state   <= S_DATA;
                        end else begin
                            state <= S_IDLE;     // falso inicio
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                // ----------------------------------------------------------
                // DATA: muestrea 8 bits en el centro de cada periodo
                // ----------------------------------------------------------
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt           <= 16'b0;
                        data_reg[bit_idx] <= rx_sync_1;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                // ----------------------------------------------------------
                // STOP: espera el bit de parada y entrega el dato
                // ----------------------------------------------------------
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        o_data  <= data_reg;
                        o_valid <= 1'b1;
                        state   <= S_IDLE;
                        clk_cnt <= 16'b0;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
