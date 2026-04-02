/***********************************************************
 * Descripcion:
 *   Transmisor UART (Universal Asynchronous Receiver
 *   Transmitter). Implementacion comportamental con
 *   maquina de estados. Formato: 1 start, 8 data (LSB
 *   primero), 1 stop, sin paridad.
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

module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,   // Frecuencia del reloj (Hz)
    parameter BAUD_RATE = 9600           // Velocidad de transmision (baudios)
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] i_data,           // Dato a transmitir
    input  wire       i_start,          // Pulso para iniciar transmision
    output reg        o_tx,             // Linea serial TX
    output wire       o_busy            // 1 = transmision en curso
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
    // Senal de ocupado
    // ========================================================================
    assign o_busy = (state != S_IDLE);

    // ========================================================================
    // Maquina de estados del transmisor
    // ========================================================================
    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            o_tx     <= 1'b1;
            clk_cnt  <= 16'b0;
            bit_idx  <= 3'b0;
            data_reg <= 8'b0;
        end else begin
            case (state)
                // ----------------------------------------------------------
                // IDLE: linea en alto, espera pulso de inicio
                // ----------------------------------------------------------
                S_IDLE: begin
                    o_tx <= 1'b1;
                    if (i_start) begin
                        data_reg <= i_data;
                        state    <= S_START;
                        clk_cnt  <= 16'b0;
                    end
                end

                // ----------------------------------------------------------
                // START: bit de inicio (linea en bajo)
                // ----------------------------------------------------------
                S_START: begin
                    o_tx <= 1'b0;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 16'b0;
                        bit_idx <= 3'b0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                // ----------------------------------------------------------
                // DATA: 8 bits de datos, LSB primero
                // ----------------------------------------------------------
                S_DATA: begin
                    o_tx <= data_reg[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 16'b0;
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
                // STOP: bit de parada (linea en alto)
                // ----------------------------------------------------------
                S_STOP: begin
                    o_tx <= 1'b1;
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
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
