# ============================================================
# Programa: Factorial via UART
# Procesador: RISC-V RV32I Single-Cycle (con extension MUL)
#
# Descripcion:
#   Recibe un byte (n) por UART RX, calcula n!, y transmite
#   el resultado de 32 bits por UART TX en 4 paquetes de
#   8 bits, comenzando por el byte mas significativo (MSB).
#
# Mapa de memoria (perifericos en 0x10010000):
#   0x10010030  UART_TX_DATA  (W)  - Dato a transmitir [7:0]
#   0x10010034  UART_RX_DATA  (R)  - Dato recibido [7:0]
#                                     (lectura limpia rx_ready)
#   0x10010038  UART_STATUS   (R)  - bit 0: tx_busy
#                                     bit 1: rx_ready
#
# Notas:
#   - Para n <= 12, el resultado cabe en 32 bits.
#     n = 12 -> 12! = 479,001,600 (0x1C8CFC00)
#   - Para n > 12, hay desbordamiento (overflow de 32 bits).
#   - RESET_VECTOR = 0x00400000
#
# Autor: Angel Habid Navarro Mendez
# Profesor: Dr. Jose Luis Pizano Escalante
# Institucion: ITESO
# Fecha: 02/04/2026
# ============================================================

.text
.globl main

main:
    # ----------------------------------------------------------
    # Inicializacion de direcciones base de perifericos
    # ----------------------------------------------------------
    auipc s0, 0xFC10          # s0 = PC + 0x0FC10000 = 0x10010000
    addi  s1, s0, 0x030       # s1 = 0x10010030 (UART_TX_DATA)
    addi  s2, s0, 0x034       # s2 = 0x10010034 (UART_RX_DATA)
    addi  s3, s0, 0x038       # s3 = 0x10010038 (UART_STATUS)

WAIT_RX:
    # ----------------------------------------------------------
    # Esperar hasta que llegue un dato por UART RX
    # ----------------------------------------------------------
    lw    t0, 0(s3)           # t0 = UART_STATUS
    andi  t0, t0, 2           # Aislar bit 1 (rx_ready)
    beq   t0, zero, WAIT_RX   # Si rx_ready == 0, seguir esperando

    # ----------------------------------------------------------
    # Leer el dato recibido (n)
    # ----------------------------------------------------------
    lw    a0, 0(s2)           # a0 = n (lectura limpia rx_ready)

    # ----------------------------------------------------------
    # Calcular factorial(n)
    #   a1 = resultado = 1
    #   Si n == 0, factorial = 1 (saltar a SEND)
    #   Sino, a1 = n * (n-1) * ... * 1
    # ----------------------------------------------------------
    addi  a1, zero, 1         # a1 = 1 (acumulador)
    beq   a0, zero, SEND      # Si n == 0, resultado = 1

FACT_LOOP:
    mul   a1, a1, a0          # a1 = a1 * a0
    addi  a0, a0, -1          # a0 = a0 - 1
    bne   a0, zero, FACT_LOOP # Repetir hasta a0 == 0

SEND:
    # ----------------------------------------------------------
    # Transmitir resultado (32 bits) en 4 bytes, MSB primero
    # ----------------------------------------------------------

    # --- Byte 3 (MSB): bits [31:24] ---
    srli  a2, a1, 24          # a2 = resultado >> 24

WAIT_TX_3:
    lw    t0, 0(s3)           # t0 = UART_STATUS
    andi  t0, t0, 1           # Aislar bit 0 (tx_busy)
    bne   t0, zero, WAIT_TX_3 # Esperar mientras tx_busy == 1
    sw    a2, 0(s1)           # Transmitir byte 3

    # --- Byte 2: bits [23:16] ---
    srli  a2, a1, 16          # a2 = resultado >> 16
    andi  a2, a2, 0xFF        # Enmascarar a 8 bits

WAIT_TX_2:
    lw    t0, 0(s3)
    andi  t0, t0, 1
    bne   t0, zero, WAIT_TX_2
    sw    a2, 0(s1)           # Transmitir byte 2

    # --- Byte 1: bits [15:8] ---
    srli  a2, a1, 8           # a2 = resultado >> 8
    andi  a2, a2, 0xFF

WAIT_TX_1:
    lw    t0, 0(s3)
    andi  t0, t0, 1
    bne   t0, zero, WAIT_TX_1
    sw    a2, 0(s1)           # Transmitir byte 1

    # --- Byte 0 (LSB): bits [7:0] ---
    andi  a2, a1, 0xFF        # a2 = resultado & 0xFF

WAIT_TX_0:
    lw    t0, 0(s3)
    andi  t0, t0, 1
    bne   t0, zero, WAIT_TX_0
    sw    a2, 0(s1)           # Transmitir byte 0

    # ----------------------------------------------------------
    # Volver a esperar siguiente entrada
    # ----------------------------------------------------------
    jal   zero, WAIT_RX
