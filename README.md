# Procesador RISC-V RV32I Single-Cycle — SoC con UART

Implementación completa de un procesador RISC-V de ciclo único (single-cycle) con periféricos memory-mapped (GPIO y UART) para la tarjeta DE10-Standard (FPGA Cyclone V 5CSXFC6D6F31C6N). El procesador ejecuta un programa que recibe un número `n` por UART desde una terminal serial, calcula el factorial `n!`, y transmite el resultado de 32 bits de vuelta por UART en 4 paquetes de 8 bits (MSB primero).

---

## Tabla de Contenidos

1. [Estructura del Proyecto](#1-estructura-del-proyecto)
2. [Arquitectura General del SoC](#2-arquitectura-general-del-soc)
3. [Mapa de Memoria](#3-mapa-de-memoria)
4. [Módulos del Procesador](#4-módulos-del-procesador)
   - 4.1 [Program Counter](#41-program-counter-program_counterv)
   - 4.2 [ROM de Instrucciones](#42-rom-de-instrucciones-rom_combinational_scv)
   - 4.3 [Unidad de Control Principal](#43-unidad-de-control-principal-main_control_rv32iv)
   - 4.4 [Control de ALU](#44-control-de-alu-control_alu_rv32iv)
   - 4.5 [Generador de Inmediatos](#45-generador-de-inmediatos-imm_generatorv)
   - 4.6 [Archivo de Registros](#46-archivo-de-registros-register_filev)
   - 4.7 [ALU](#47-alu-alu_riscv_rv32iv)
   - 4.8 [Multiplicador](#48-multiplicador-mul_modulev)
   - 4.9 [Unidad de Branch](#49-unidad-de-branch-branch_unitv)
   - 4.10 [Multiplexores](#410-multiplexores)
   - 4.11 [Sumador de 32 bits](#411-sumador-de-32-bits-adder_4_32bv)
5. [Core RV32I Single-Cycle (Datapath)](#5-core-rv32i-single-cycle-datapath)
6. [Periféricos](#6-periféricos)
   - 6.1 [Decodificador de Direcciones](#61-decodificador-de-direcciones-addr_decoderv)
   - 6.2 [GPIO](#62-gpio-gpio_peripheralv)
   - 6.3 [UART](#63-uart)
7. [Programa de Factorial](#7-programa-de-factorial)
8. [Conjunto de Instrucciones Soportadas](#8-conjunto-de-instrucciones-soportadas)
9. [Pinout FPGA](#9-pinout-fpga)
10. [Simulación](#10-simulación)
11. [Notas de Diseño](#11-notas-de-diseño)
12. [Diagramas](#12-diagramas)

---

## 1. Estructura del Proyecto

```
riscv-single-cycle-soc/
├── rtl/                                       # Hardware (RTL Verilog)
│   ├── core/                                  #   CPU RV32I internals
│   │   ├── program_counter/                   #     Contador de programa
│   │   ├── register_file/                     #     Archivo de registros (32×32-bit)
│   │   ├── alu_riscv_rv32i/                   #     ALU (10 operaciones)
│   │   ├── control_alu_rv32i/                 #     Control de ALU (funct3/funct7)
│   │   ├── main_control_rv32i/                #     Unidad de control principal
│   │   ├── imm_generator/                     #     Generador de inmediatos
│   │   ├── branch_unit/                       #     Evaluador de condiciones de branch
│   │   ├── mul_module/                        #     Multiplicador (RV32M: MUL)
│   │   ├── mux_2i_1o/                         #     Multiplexor 2:1
│   │   ├── mux_4i_1o/                         #     Multiplexor 4:1
│   │   ├── adder_4_32b/                       #     Sumador de 32 bits
│   │   └── rv32i_single_cycle/                #     Core top-level (datapath)
│   ├── memory/                                #   Memorias
│   │   ├── rom_combinational_sc/              #     ROM de instrucciones (64×32-bit)
│   │   └── data_memory/                       #     RAM de datos (256×32-bit)
│   ├── peripherals/                           #   Periféricos memory-mapped
│   │   ├── addr_decoder/                      #     Decodificador de direcciones
│   │   ├── gpio_peripheral/                   #     GPIO (LEDs/switches)
│   │   ├── uart_tx/                           #     Transmisor UART
│   │   ├── uart_rx/                           #     Receptor UART
│   │   └── uart_peripheral/                   #     UART wrapper memory-mapped
│   └── soc/                                   #   Integración top-level
│       └── soc_rv32i_single_cycle/            #     SoC completo
│           ├── source/                        #       RTL + testbench legacy
│           ├── quartus_project/               #       Proyecto Quartus (síntesis)
│           └── questa_project/                #       Proyecto Questa (simulación)
│               └── soc_uart_factorial_tb.v    #         Testbench factorial UART
├── sw/                                        # Software (ensamblador RISC-V)
│   └── factorial_uart.asm                     #   Programa factorial via UART
├── docs/                                      # Documentación
│   └── diagrams/                              #   Diagramas draw.io (editables)
│       ├── 01_soc_architecture.drawio
│       ├── 02_rv32i_datapath.drawio
│       ├── 03_uart_system.drawio
│       ├── 04_memory_map.drawio
│       └── 05_uart_timing.drawio
├── project_template/                          # Plantilla de módulo Quartus
│   ├── quartus_project/
│   ├── questa_project/
│   └── source/
└── README.md
```

> **Nota:** Cada módulo dentro de `rtl/` mantiene la estructura del template del profesor:
> `{módulo}/source/`, `{módulo}/quartus_project/`, `{módulo}/questa_project/`.

---

## 2. Arquitectura General del SoC

> **Diagrama interactivo:** [`docs/diagrams/01_soc_architecture.drawio`](docs/diagrams/01_soc_architecture.drawio) — Abrir con [draw.io](https://app.diagrams.net/) o la extensión *Draw.io Integration* de VS Code.
>
> Para generar la imagen PNG/SVG: Abrir el `.drawio` → File → Export as → PNG/SVG → guardar en `docs/diagrams/` como `01_soc_architecture.png`.

<!-- Descomentar cuando se exporten las imágenes:
![Arquitectura del SoC](docs/diagrams/01_soc_architecture.png)
-->

El SoC sigue una arquitectura Harvard con buses separados para instrucciones y datos. El diseño es **estructural** a nivel de SoC y core: cada módulo constitutivo (ALU, registros, control, etc.) se instancia explícitamente y se conecta mediante cables. Los módulos internos pueden usar modelado **comportamental** (always blocks, case statements).

```
                         ┌─────────────────────────────────────────────────────┐
                         │                   SoC Top-Level                     │
                         │            (soc_rv32i_single_cycle)                 │
                         │                                                     │
                         │  ┌───────────────────────────────────────────────┐  │
                         │  │          Core RV32I Single-Cycle              │  │
                         │  │          (rv32i_single_cycle)                 │  │
                         │  │                                               │  │
                         │  │  ┌────────┐  ┌──────────────┐  ┌──────────┐  │  │
                         │  │  │   PC   │─→│  Instruction  │─→│  Main    │  │  │
                         │  │  │        │  │   Memory Bus  │  │  Control │  │  │
                         │  │  └───┬────┘  └──────────────┘  └────┬─────┘  │  │
                         │  │      │                               │        │  │
                         │  │  ┌───┴────┐  ┌──────────┐  ┌───────┴──────┐  │  │
                         │  │  │ Adder  │  │ Register │  │  ALU Control │  │  │
                         │  │  │ PC + 4 │  │   File   │  └───────┬──────┘  │  │
                         │  │  └────────┘  └────┬─────┘          │         │  │
                         │  │                   │         ┌──────┴───────┐  │  │
                         │  │  ┌────────────┐   │         │     ALU      │  │  │
                         │  │  │    Imm     │   │         └──────┬───────┘  │  │
                         │  │  │ Generator  │   │                │         │  │
                         │  │  └────────────┘   │         ┌──────┴───────┐  │  │
                         │  │                   │         │ Multiplier   │  │  │
                         │  │  ┌────────────┐   │         └──────────────┘  │  │
                         │  │  │  Branch    │   │                           │  │
                         │  │  │   Unit     │   │    ┌─── Data Memory Bus  │  │
                         │  │  └────────────┘   │    │                     │  │
                         │  └───────────────────┼────┼─────────────────────┘  │
                         │                      │    │                        │
                         │  ┌───────────────────┴────┴──────────────────────┐ │
                         │  │            Address Decoder                     │ │
                         │  │            (addr_decoder)                      │ │
                         │  └──────┬──────────────┬──────────────┬──────────┘ │
                         │         │              │              │            │
                         │    ┌────┴────┐   ┌─────┴─────┐  ┌────┴────┐       │
                         │    │  Data   │   │   GPIO    │  │  UART   │       │
                         │    │ Memory  │   │Peripheral │  │Peripheral│      │
                         │    │ (RAM)   │   │           │  │          │      │
                         │    └─────────┘   └─────┬─────┘  └────┬────┘       │
                         │                        │             │            │
                         └────────────────────────┼─────────────┼────────────┘
                                                  │             │
                                            LEDR[7:0]     TX (PIN_W15)
                                            SW[7:0]       RX (PIN_AK2)
```

### Parámetros del SoC

| Parámetro | Valor por defecto | Descripción |
|-----------|-------------------|-------------|
| `IMEM_DEPTH` | 64 | Profundidad de la ROM de instrucciones (palabras de 32 bits) |
| `DMEM_DEPTH` | 256 | Profundidad de la RAM de datos (palabras de 32 bits) |
| `RESET_VECTOR` | `32'h0040_0000` | Dirección inicial del PC tras reset |
| `HEX_FILE` | `"program.hex"` | Archivo HEX para inicializar la ROM (no usado; programa hardcoded) |
| `CLK_FREQ` | `50_000_000` | Frecuencia del reloj del sistema en Hz (50 MHz) |
| `BAUD_RATE` | `9600` | Velocidad de la UART en baudios |

---

## 3. Mapa de Memoria

> **Diagrama interactivo:** [`docs/diagrams/04_memory_map.drawio`](docs/diagrams/04_memory_map.drawio) — Mapa de memoria completo con lógica de decodificación y registros de periféricos.

<!-- Descomentar cuando se exporten las imágenes:
![Mapa de Memoria](docs/diagrams/04_memory_map.png)
-->

El procesador utiliza un espacio de direcciones de 32 bits. El decodificador de direcciones divide el espacio en tres regiones según los bits superiores de la dirección:

### 3.1 Vista General

| Rango de Direcciones | Componente | Tamaño | Acceso |
|----------------------|------------|--------|--------|
| `0x0040_0000` — `0x0040_00FC` | ROM de Instrucciones | 64 palabras (256 bytes) | Solo lectura (bus de instrucciones) |
| `0x1001_0000` — `0x1001_001F` | RAM de Datos | 256 palabras (1 KB) | Lectura/Escritura |
| `0x1001_0024` | GPIO_OUT | 4 bytes | Escritura (LEDs) / Lectura |
| `0x1001_0028` | GPIO_IN | 4 bytes | Solo lectura (Switches) |
| `0x1001_0030` | UART_TX_DATA | 4 bytes | Solo escritura |
| `0x1001_0034` | UART_RX_DATA | 4 bytes | Solo lectura (limpia `rx_ready`) |
| `0x1001_0038` | UART_STATUS | 4 bytes | Solo lectura |
| Todo lo demás | RAM de Datos (alias) | — | Lectura/Escritura |

### 3.2 Lógica de Decodificación

La decodificación se realiza en dos niveles:

**Nivel 1 — Espacio de periféricos:**
```
is_periph = (i_addr[31:16] == 16'h1001)
```
Cualquier dirección cuyo half-word superior sea `0x1001` pertenece al espacio de periféricos.

**Nivel 2 — Selección de periférico:**
```
is_gpio = is_periph AND (i_addr[7:4] == 4'h2)    →  offsets 0x20–0x2F
is_uart = is_periph AND (i_addr[7:4] == 4'h3)    →  offsets 0x30–0x3F
is_dmem = NOT(is_gpio) AND NOT(is_uart)           →  todo lo demás
```

Los chip-select se activan solo cuando hay una operación de lectura o escritura pendiente:
```
o_cs_dmem = is_dmem AND (mem_we OR mem_re)
o_cs_gpio = is_gpio AND (mem_we OR mem_re)
o_cs_uart = is_uart AND (mem_we OR mem_re)
```

### 3.3 Registros UART (detalle)

| Offset | Nombre | Bits | R/W | Descripción |
|--------|--------|------|-----|-------------|
| `0x30` | `UART_TX_DATA` | `[7:0]` | W | Byte a transmitir. La escritura inicia la transmisión si `tx_busy == 0`. |
| `0x34` | `UART_RX_DATA` | `[7:0]` | R | Último byte recibido. La lectura limpia automáticamente la bandera `rx_ready`. |
| `0x38` | `UART_STATUS` | `[1:0]` | R | Bit 0: `tx_busy` (1 = transmisión en curso). Bit 1: `rx_ready` (1 = dato disponible). |

### 3.4 Registros GPIO (detalle)

| Offset | Nombre | Bits | R/W | Descripción |
|--------|--------|------|-----|-------------|
| `0x24` | `GPIO_OUT` | `[7:0]` | R/W | Registro de salida conectado a LEDs `LEDR[7:0]`. |
| `0x28` | `GPIO_IN` | `[7:0]` | R | Lectura directa de switches `SW[7:0]`. |

### 3.5 Multiplexión del Dato de Lectura

Cuando el core realiza una lectura (`lw`), el decodificador de direcciones selecciona el dato de respuesta según prioridad:
1. Si `is_uart`: devuelve `uart_rdata`
2. Si `is_gpio`: devuelve `gpio_rdata`
3. De lo contrario: devuelve `dmem_rdata`

### 3.6 Direccionamiento de la RAM

La RAM de datos utiliza direccionamiento a nivel de palabra. Los 2 bits menos significativos de la dirección se descartan:

```
word_addr = i_addr[31:2]
```

Para una RAM de 256 palabras, solamente los 8 bits bajos de `word_addr` (equivalente a `i_addr[9:2]`) seleccionan la celda. Esto significa que la dirección `0x1001_0000` accede a `mem_array[0]`, la dirección `0x1001_0004` accede a `mem_array[1]`, y así sucesivamente hasta `0x1001_03FC` que accede a `mem_array[255]`.

Las direcciones de periféricos (`0x24`, `0x28`, `0x30`, `0x34`, `0x38`) dentro de este rango son interceptadas por el decodificador antes de llegar a la RAM, por lo que las celdas correspondientes (`mem_array[9]`, `mem_array[10]`, `mem_array[12]`–`mem_array[14]`) quedan "sombradas" (shadowed) y no son accesibles desde el software.

---

## 4. Módulos del Procesador

### 4.1 Program Counter (`program_counter.v`)

Registro síncrono de 32 bits que almacena la dirección de la instrucción actual.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `clk` | 1 | Entrada | Reloj del sistema |
| `rst` | 1 | Entrada | Reset síncrono (activo en alto) |
| `en` | 1 | Entrada | Habilitación de escritura |
| `i_next_pc` | 32 | Entrada | Siguiente valor del PC |
| `o_pc` | 32 | Salida | Valor actual del PC |

**Parámetros:**

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `WIDTH` | 32 | Ancho del registro |
| `RESET_VECTOR` | `32'h0000_0000` | Valor inicial tras reset (el SoC lo sobreescribe a `32'h0040_0000`) |

**Comportamiento:**
- En el flanco de subida del reloj:
  - Si `rst == 1`: `o_pc <= RESET_VECTOR`
  - Si `rst == 0` y `en == 1`: `o_pc <= i_next_pc`
  - Si `rst == 0` y `en == 0`: `o_pc` mantiene su valor anterior
- En el SoC, la señal `en` está permanentemente conectada a `1'b1`, por lo que el PC se actualiza en cada ciclo de reloj.

---

### 4.2 ROM de Instrucciones (`rom_combinational_sc.v`)

Memoria de instrucciones implementada como lógica combinacional pura mediante un `case` statement. Quartus sintetiza esto en LUTs (Look-Up Tables).

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_pc_addr` | 32 | Entrada | Dirección de la instrucción (valor del PC) |
| `o_instruction` | 32 | Salida | Instrucción de 32 bits decodificada |

**Parámetros:**

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `DEPTH` | 64 | Número de palabras almacenables |
| `HEX_FILE` | `"program.hex"` | No utilizado en la implementación actual |

**Cálculo de la dirección de palabra:**

```verilog
wire [$clog2(DEPTH)-1:0] word_addr = i_pc_addr[$clog2(DEPTH)-1+2:2];
```

Para `DEPTH = 64`: `$clog2(64) = 6`, por lo tanto:
```
word_addr[5:0] = i_pc_addr[7:2]
```

Esto extrae 6 bits de la dirección del PC (descartando los 2 bits de byte-offset), lo que permite direccionar 64 palabras. La dirección `0x0040_0000` da `word_addr = 0`, `0x0040_0004` da `word_addr = 1`, etc.

**Contenido actual:** 36 instrucciones del programa de factorial via UART (ver [Sección 7](#7-programa-de-factorial)). Las direcciones no utilizadas (`word_addr` 36–63) devuelven `NOP` (`32'h00000013`).

---

### 4.3 Unidad de Control Principal (`main_control_rv32i.v`)

Decodifica el campo opcode de 7 bits (`instruction[6:0]`) y genera 10 señales de control que gobiernan el datapath.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_opcode` | 7 | Entrada | Opcode de la instrucción `[6:0]` |
| `o_reg_write` | 1 | Salida | Habilita escritura en el archivo de registros |
| `o_result_src` | 2 | Salida | Selecciona la fuente del dato de write-back |
| `o_mem_write` | 1 | Salida | Habilita escritura en memoria de datos |
| `o_mem_read` | 1 | Salida | Habilita lectura de memoria de datos |
| `o_branch` | 1 | Salida | Indica instrucción tipo branch |
| `o_jump` | 1 | Salida | Indica salto incondicional (JAL o JALR) |
| `o_jalr` | 1 | Salida | Distingue JALR de JAL |
| `o_alu_op` | 2 | Salida | Clase de operación para el control de ALU |
| `o_alu_src` | 1 | Salida | Selecciona operando B de la ALU (0=rs2, 1=inmediato) |
| `o_alu_a_src` | 1 | Salida | Selecciona operando A de la ALU (0=rs1, 1=PC) |

**Tabla de verdad completa:**

| Opcode | Tipo | `reg_write` | `result_src` | `mem_write` | `mem_read` | `branch` | `jump` | `jalr` | `alu_op` | `alu_src` | `alu_a_src` |
|--------|------|:-----------:|:------------:|:-----------:|:----------:|:--------:|:------:|:------:|:--------:|:---------:|:-----------:|
| `0110011` | R-type | 1 | `00` | 0 | 0 | 0 | 0 | 0 | `10` | 0 | 0 |
| `0010011` | I-type ALU | 1 | `00` | 0 | 0 | 0 | 0 | 0 | `10` | 1 | 0 |
| `0000011` | Load | 1 | `01` | 0 | 1 | 0 | 0 | 0 | `00` | 1 | 0 |
| `0100011` | Store | 0 | `XX` | 1 | 0 | 0 | 0 | 0 | `00` | 1 | 0 |
| `1100011` | Branch | 0 | `XX` | 0 | 0 | 1 | 0 | 0 | `01` | 0 | 0 |
| `0110111` | LUI | 1 | `11` | 0 | 0 | 0 | 0 | 0 | `00` | 0 | 0 |
| `0010111` | AUIPC | 1 | `00` | 0 | 0 | 0 | 0 | 0 | `00` | 1 | 1 |
| `1101111` | JAL | 1 | `10` | 0 | 0 | 0 | 1 | 0 | `00` | 0 | 0 |
| `1100111` | JALR | 1 | `10` | 0 | 0 | 0 | 1 | 1 | `00` | 1 | 0 |

**Codificación de `result_src`:**
- `00`: Resultado de la ALU (instrucciones R-type, I-ALU, AUIPC)
- `01`: Dato leído de memoria (instrucciones Load)
- `10`: PC + 4 (dirección de retorno para JAL y JALR)
- `11`: Inmediato (LUI)

**Codificación de `alu_op`:**
- `00`: Operación ADD para cálculo de dirección (Load/Store/AUIPC) o no importa (LUI/JAL/JALR)
- `01`: Operación SUB para comparación de branch
- `10`: Operación determinada por funct3/funct7 (R-type e I-type ALU)

---

### 4.4 Control de ALU (`control_alu_rv32i.v`)

Segundo nivel de decodificación. Recibe `alu_op` del control principal y los campos `funct3`, `funct7` de la instrucción para generar la señal de control de 4 bits que selecciona la operación específica de la ALU.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_alu_op` | 2 | Entrada | Clase de operación del control principal |
| `i_funct3` | 3 | Entrada | Campo funct3 de la instrucción `[14:12]` |
| `i_funct7_5` | 1 | Entrada | Bit 30 de la instrucción (funct7[5]) |
| `i_funct7_0` | 1 | Entrada | Bit 25 de la instrucción (funct7[0]) |
| `i_op5` | 1 | Entrada | Bit 5 del opcode (distingue R-type de I-type) |
| `o_alu_ctrl` | 4 | Salida | Señal de control de 4 bits para la ALU |
| `o_mul_sel` | 1 | Salida | Selección del multiplicador (1 = usar resultado MUL) |

**Tabla de decodificación completa:**

| `alu_op` | `funct3` | `funct7_5` | `funct7_0` | `op5` | `alu_ctrl` | `mul_sel` | Operación |
|:--------:|:--------:|:----------:|:----------:|:-----:|:----------:|:---------:|-----------|
| `00` | X | X | X | X | `0010` | 0 | ADD (cálculo de dirección) |
| `01` | X | X | X | X | `0110` | 0 | SUB (comparación de branch) |
| `10` | `000` | X | 1 | 1 | `0000`* | **1** | **MUL** (extensión RV32M) |
| `10` | `000` | 1 | X | 1 | `0110` | 0 | SUB (R-type, funct7=0x20) |
| `10` | `000` | X | X | 0 | `0010` | 0 | ADD/ADDI |
| `10` | `000` | 0 | 0 | 1 | `0010` | 0 | ADD (R-type, funct7=0x00) |
| `10` | `001` | X | X | X | `0111` | 0 | SLL / SLLI |
| `10` | `010` | X | X | X | `1001` | 0 | SLT / SLTI |
| `10` | `011` | X | X | X | `1010` | 0 | SLTU / SLTIU |
| `10` | `100` | X | X | X | `0100` | 0 | XOR / XORI |
| `10` | `101` | 1 | X | X | `1000` | 0 | SRA / SRAI |
| `10` | `101` | 0 | X | X | `0101` | 0 | SRL / SRLI |
| `10` | `110` | X | X | X | `0001` | 0 | OR / ORI |
| `10` | `111` | X | X | X | `0000` | 0 | AND / ANDI |

> *Nota sobre MUL: cuando `mul_sel = 1`, el resultado de la ALU es ignorado y se usa el resultado del módulo multiplicador. El valor de `alu_ctrl` es irrelevante en este caso.

**Detalle crítico — Guardia ADDI:**

La distinción entre `SUB` (R-type) y `ADDI` (I-type) cuando `funct3 = 000` y `funct7_5 = 1` se resuelve con el bit `op5` (bit 5 del opcode):

- R-type (`ADD`/`SUB`): opcode = `0110011`, por lo tanto `op5 = 1`
- I-type ALU (`ADDI`): opcode = `0010011`, por lo tanto `op5 = 0`

Cuando `op5 = 0` (I-type), el bit `funct7_5` proviene del bit 30 del inmediato (que puede ser 1 para valores negativos como `addi x1, x2, -1`) y **no** indica SUB. Esta guardia evita que un `ADDI` con inmediato negativo sea interpretado erróneamente como `SUB`.

La misma lógica aplica para la detección de MUL: se verifica que `op5 = 1` (R-type) y `funct7_0 = 1` antes de activar `mul_sel`.

---

### 4.5 Generador de Inmediatos (`imm_generator.v`)

Extrae y extiende el signo del campo inmediato de la instrucción según su tipo (I, S, B, U, J).

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_instr` | 32 | Entrada | Instrucción completa de 32 bits |
| `o_imm` | 32 | Salida | Inmediato de 32 bits con extensión de signo |

**Generación por tipo de instrucción:**

| Opcode | Tipo | Fórmula de extracción |
|--------|------|-----------------------|
| `0000011` (Load) | I-type | `{{21{instr[31]}}, instr[30:20]}` |
| `0010011` (I-ALU) | I-type | `{{21{instr[31]}}, instr[30:20]}` |
| `1100111` (JALR) | I-type | `{{21{instr[31]}}, instr[30:20]}` |
| `0100011` (Store) | S-type | `{{21{instr[31]}}, instr[30:25], instr[11:7]}` |
| `1100011` (Branch) | B-type | `{{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}` |
| `0110111` (LUI) | U-type | `{instr[31:12], 12'b0}` |
| `0010111` (AUIPC) | U-type | `{instr[31:12], 12'b0}` |
| `1101111` (JAL) | J-type | `{{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}` |

**Detalles importantes:**
- **Extensión de signo**: todos los inmediatos (excepto U-type) se extienden con el bit de signo (`instr[31]`). Esto permite representar valores negativos correctamente en complemento a dos.
- **Bit 0 implícito**: los inmediatos de tipo B y J tienen el bit 0 siempre en `0` (multiplica la resolución por 2, alineando a half-word).
- **U-type**: los 20 bits superiores se colocan directamente en `[31:12]` y los 12 bits inferiores se llenan con ceros.
- **Tipo por defecto**: si el opcode no coincide con ninguno de los anteriores, el inmediato se fija en `32'b0`.

---

### 4.6 Archivo de Registros (`register_file.v`)

Implementa los 32 registros de propósito general del RV32I con 2 puertos de lectura asíncrona y 1 puerto de escritura síncrona.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `clk` | 1 | Entrada | Reloj del sistema |
| `i_we` | 1 | Entrada | Habilitación de escritura |
| `i_rd` | 5 | Entrada | Dirección del registro destino |
| `i_wdata` | 32 | Entrada | Dato a escribir |
| `i_rs1` | 5 | Entrada | Dirección del registro fuente 1 |
| `o_rdata1` | 32 | Salida | Dato leído del registro fuente 1 |
| `i_rs2` | 5 | Entrada | Dirección del registro fuente 2 |
| `o_rdata2` | 32 | Salida | Dato leído del registro fuente 2 |

**Implementación interna:**

```
registers[0:31]  —  arreglo de 32 registros de 32 bits
```

**Lecturas (combinacionales):**
```
o_rdata1 = (i_rs1 == 0) ? 32'b0 : registers[i_rs1]
o_rdata2 = (i_rs2 == 0) ? 32'b0 : registers[i_rs2]
```

**Escritura (síncrona, flanco de subida):**
```
if (i_we AND i_rd != 0):
    registers[i_rd] <= i_wdata
```

**Características clave:**
- El registro `x0` siempre devuelve `0` al ser leído, sin importar lo que se haya intentado escribir.
- Las escrituras al registro `x0` son descartadas silenciosamente (`i_rd != 5'd0`).
- Las lecturas son **combinacionales** (asíncronas): el dato está disponible inmediatamente sin esperar un flanco de reloj.
- Las escrituras son **síncronas**: ocurren en el flanco positivo del reloj.
- No existe lógica de bypass o forwarding (no es necesaria en una arquitectura single-cycle porque la lectura y la escritura del mismo ciclo no se solapan en registros diferentes).

**Nomenclatura ABI de registros RISC-V:**

| Registro | ABI | Uso |
|----------|-----|-----|
| `x0` | `zero` | Siempre vale 0 (hardwired) |
| `x1` | `ra` | Dirección de retorno |
| `x2` | `sp` | Stack pointer |
| `x5`–`x7` | `t0`–`t2` | Temporales |
| `x8` | `s0`/`fp` | Registro salvado / frame pointer |
| `x9` | `s1` | Registro salvado |
| `x10`–`x11` | `a0`–`a1` | Argumentos / valores de retorno |
| `x12`–`x17` | `a2`–`a7` | Argumentos de función |
| `x18`–`x27` | `s2`–`s11` | Registros salvados |
| `x28`–`x31` | `t3`–`t6` | Temporales |

---

### 4.7 ALU (`alu_riscv_rv32i.v`)

Unidad aritmético-lógica de 32 bits que soporta 10 operaciones seleccionadas por una señal de control de 4 bits.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_a` | 32 | Entrada | Operando A |
| `i_b` | 32 | Entrada | Operando B |
| `i_alu_ctrl` | 4 | Entrada | Selección de operación |
| `o_result` | 32 | Salida | Resultado de la operación |
| `o_zero` | 1 | Salida | Bandera de cero: `1` si `o_result == 0` |

**Tabla de operaciones:**

| `i_alu_ctrl` | Operación | Expresión Verilog | Instrucciones |
|:------------:|-----------|-------------------|---------------|
| `0000` | AND | `i_a & i_b` | `AND`, `ANDI` |
| `0001` | OR | `i_a \| i_b` | `OR`, `ORI` |
| `0010` | ADD | `i_a + i_b` | `ADD`, `ADDI`, Load/Store (dirección), `AUIPC` |
| `0100` | XOR | `i_a ^ i_b` | `XOR`, `XORI` |
| `0101` | SRL | `i_a >> i_b[4:0]` | `SRL`, `SRLI` |
| `0110` | SUB | `i_a - i_b` | `SUB`, Branch (comparación) |
| `0111` | SLL | `i_a << i_b[4:0]` | `SLL`, `SLLI` |
| `1000` | SRA | `$signed(i_a) >>> i_b[4:0]` | `SRA`, `SRAI` |
| `1001` | SLT | `($signed(i_a) < $signed(i_b)) ? 1 : 0` | `SLT`, `SLTI` |
| `1010` | SLTU | `(i_a < i_b) ? 1 : 0` | `SLTU`, `SLTIU` |

**Detalles:**
- **Shifts**: el monto de desplazamiento es siempre `i_b[4:0]` (5 bits), conforme a la especificación RV32I.
- **SRA vs SRL**: `SRA` usa `$signed()` y `>>>` para preservar el bit de signo durante el desplazamiento aritmético a la derecha. `SRL` usa `>>` que inserta ceros por la izquierda.
- **SLT/SLTU**: retornan un resultado de 32 bits (`32'd1` o `32'd0`), no solo 1 bit. SLT compara con signo; SLTU compara sin signo.
- **Bandera `o_zero`**: se calcula como `o_result == 32'b0`. Está disponible pero no es utilizada directamente por la unidad de branch (la cual realiza sus propias comparaciones).

---

### 4.8 Multiplicador (`mul_module.v`)

Multiplicador combinacional de 32x32 bits. Implementa la instrucción `MUL` de la extensión RV32M.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_a` | 32 | Entrada | Multiplicando (rs1) |
| `i_b` | 32 | Entrada | Multiplicador (rs2) |
| `o_result` | 32 | Salida | 32 bits inferiores del producto |

**Implementación interna:**
```verilog
wire [63:0] product = i_a * i_b;
assign o_result = product[31:0];
```

**Detalles:**
- El producto completo es de 64 bits (`i_a × i_b`), pero solo se devuelven los 32 bits inferiores (`product[31:0]`), conforme a la especificación de la instrucción `MUL`.
- Para los 32 bits inferiores, el signo de los operandos no afecta el resultado (la representación en complemento a dos produce los mismos bits bajos).
- El módulo es **puramente combinacional**. La herramienta de síntesis de Quartus lo mapeará a bloques DSP embebidos del FPGA.
- Se conecta en paralelo con la ALU en el datapath. El multiplexor `u_mux_mul` selecciona entre el resultado de la ALU y el resultado del multiplicador según la señal `mul_sel`.

---

### 4.9 Unidad de Branch (`branch_unit.v`)

Evalúa las condiciones de branch comparando los valores de los registros `rs1` y `rs2`.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_rs1_data` | 32 | Entrada | Dato del registro fuente 1 |
| `i_rs2_data` | 32 | Entrada | Dato del registro fuente 2 |
| `i_funct3` | 3 | Entrada | Tipo de comparación `[14:12]` |
| `i_branch` | 1 | Entrada | Señal de control: instrucción es branch |
| `i_jump` | 1 | Entrada | Señal de control: instrucción es jump |
| `o_pc_sel` | 1 | Salida | Selección del siguiente PC (0=PC+4, 1=target) |

**Tabla de condiciones de branch:**

| `funct3` | Instrucción | Condición | Tipo de comparación |
|:--------:|-------------|-----------|---------------------|
| `000` | `BEQ` | `rs1 == rs2` | Igualdad |
| `001` | `BNE` | `rs1 != rs2` | Desigualdad |
| `100` | `BLT` | `$signed(rs1) < $signed(rs2)` | Menor que (con signo) |
| `101` | `BGE` | `$signed(rs1) >= $signed(rs2)` | Mayor o igual (con signo) |
| `110` | `BLTU` | `rs1 < rs2` | Menor que (sin signo) |
| `111` | `BGEU` | `rs1 >= rs2` | Mayor o igual (sin signo) |

**Lógica de selección del PC:**
```
o_pc_sel = i_jump OR (i_branch AND branch_taken)
```

- Para instrucciones **JAL** y **JALR**: `i_jump = 1`, por lo que `o_pc_sel = 1` siempre (salto incondicional).
- Para instrucciones **Branch**: `i_branch = 1`, y `o_pc_sel = 1` solo si la condición evaluada es verdadera.
- Para todas las demás instrucciones: `i_branch = 0` y `i_jump = 0`, por lo que `o_pc_sel = 0` (PC avanza a PC + 4).

---

### 4.10 Multiplexores

#### 4.10.1 Multiplexor 2:1 (`mux_2i_1o.v`)

```verilog
assign o_out = (i_sel) ? i_d1 : i_d0;
```

| `i_sel` | `o_out` |
|:-------:|---------|
| 0 | `i_d0` |
| 1 | `i_d1` |

Se instancia 4 veces en el core:

| Instancia | Selección (`i_sel`) | `i_d0` (sel=0) | `i_d1` (sel=1) | Propósito |
|-----------|:-------------------:|-----------------|-----------------|-----------|
| `u_mux_alu_a` | `ctrl_alu_a_src` | `rs1_data` | `pc_current` | Operando A de ALU |
| `u_mux_alu_b` | `ctrl_alu_src` | `rs2_data` | `immediate` | Operando B de ALU |
| `u_mux_jalr` | `ctrl_jalr` | `pc_branch_target` | `pc_jalr_target` | Target de salto |
| `u_mux_pc_next` | `pc_sel` | `pc_plus_4` | `pc_target` | Siguiente PC |
| `u_mux_mul` | `mul_sel` | `wb_result_mux` | `mul_result` | ALU vs MUL |

#### 4.10.2 Multiplexor 4:1 (`mux_4i_1o.v`)

| `i_sel` | `o_out` |
|:-------:|---------|
| `00` | `i_d0` |
| `01` | `i_d1` |
| `10` | `i_d2` |
| `11` | `i_d3` |

Se instancia 1 vez en el core como `u_mux_result`:

| `i_sel` (`result_src`) | Fuente | Instrucciones |
|:-----------------------:|--------|---------------|
| `00` | Resultado ALU | R-type, I-ALU, AUIPC |
| `01` | Dato de memoria | Load (LW) |
| `10` | PC + 4 | JAL, JALR (dirección de retorno) |
| `11` | Inmediato | LUI |

---

### 4.11 Sumador de 32 bits (`adder_4_32b.v`)

```verilog
assign o_sum = i_a + i_b;
```

Sumador puramente combinacional sin detección de overflow. Se instancia 2 veces en el core:

| Instancia | `i_a` | `i_b` | `o_sum` | Propósito |
|-----------|-------|-------|---------|-----------|
| `u_pc_add4` | `pc_current` | `32'd4` | `pc_plus_4` | Calcular siguiente dirección secuencial |
| `u_pc_add_imm` | `pc_current` | `immediate` | `pc_branch_target` | Calcular dirección destino de branch/JAL |

---

## 5. Core RV32I Single-Cycle (Datapath)

> **Diagrama interactivo:** [`docs/diagrams/02_rv32i_datapath.drawio`](docs/diagrams/02_rv32i_datapath.drawio) — Datapath detallado con las 5 etapas (Fetch, Decode, Execute, Memory, Write-Back), señales de control por tipo de instrucción, y lógica de Next PC.

<!-- Descomentar cuando se exporten las imágenes:
![Datapath RV32I](docs/diagrams/02_rv32i_datapath.png)
-->

El módulo `rv32i_single_cycle.v` es el corazón del procesador. Contiene exclusivamente la **instanciación estructural** de todos los submódulos y sus interconexiones. No contiene lógica comportamental propia (excepto asignaciones `assign` para conexión de buses).

### 5.1 Etapa de Busqueda de Instrucción (Instruction Fetch)

```
          ┌──────────┐
          │ Program  │ o_pc ──────────────→ o_imem_addr (bus a ROM)
   rst ──→│ Counter  │                │
          └──────────┘                │
               ↑                      ↓
          i_next_pc              ┌──────────┐
               │                 │ Adder    │
               │                 │ PC + 4   │──→ pc_plus_4
               │                 └──────────┘
               │
          ┌──────────┐
          │ MUX      │
          │ pc_next  │←── pc_sel (de branch_unit)
          │ d0=PC+4  │
          │ d1=target│
          └──────────┘
```

1. El **Program Counter** (`u_pc`) mantiene la dirección de la instrucción actual (`pc_current`).
2. Este valor se envía al bus de instrucciones (`o_imem_addr`), donde la ROM combinacional devuelve la instrucción correspondiente.
3. El **sumador `u_pc_add4`** calcula `pc_current + 4` para obtener la dirección de la siguiente instrucción secuencial.
4. El **MUX `u_mux_pc_next`** selecciona entre `pc_plus_4` (avance secuencial) y `pc_target` (salto/branch), según la señal `pc_sel` generada por la unidad de branch.

### 5.2 Etapa de Decodificación (Decode)

```
  instruction ───┬──→ opcode[6:0]    ──→ main_control_rv32i ──→ señales de control
                 ├──→ rd[11:7]
                 ├──→ funct3[14:12]  ──→ control_alu_rv32i  ──→ alu_ctrl, mul_sel
                 ├──→ rs1[19:15]     ──→ register_file      ──→ rs1_data
                 ├──→ rs2[24:20]     ──→ register_file      ──→ rs2_data
                 ├──→ funct7_5 [30]
                 ├──→ funct7_0 [25]
                 ├──→ op5 [5]
                 └──→ i_instr        ──→ imm_generator       ──→ immediate
```

La instrucción de 32 bits se descompone en sus campos constituyentes mediante asignaciones directas:
- `opcode = instruction[6:0]`
- `rd = instruction[11:7]`
- `funct3 = instruction[14:12]`
- `rs1_addr = instruction[19:15]`
- `rs2_addr = instruction[24:20]`
- `funct7_5 = instruction[30]`
- `funct7_0 = instruction[25]`
- `op5 = instruction[5]`

### 5.3 Etapa de Ejecución (Execute)

```
  rs1_data ──→┌──────────┐          ┌──────────┐
              │ MUX A    │──→ i_a ──│          │
  pc_current→│ sel=     │          │   ALU    │──→ alu_result
              │ alu_a_src│          │          │
              └──────────┘          └──────────┘
                                         ↑
  rs2_data ──→┌──────────┐          i_alu_ctrl
              │ MUX B    │──→ i_b       │
  immediate──→│ sel=     │       control_alu_rv32i
              │ alu_src  │
              └──────────┘

  rs1_data ──→┌──────────┐
              │  MUL     │──→ mul_result
  rs2_data ──→│ Module   │
              └──────────┘
```

- **MUX A (`u_mux_alu_a`)**: selecciona `rs1_data` (para operaciones R/I/S/B) o `pc_current` (para AUIPC).
- **MUX B (`u_mux_alu_b`)**: selecciona `rs2_data` (para R-type y Branch) o `immediate` (para I-type, Load, Store, AUIPC, JALR).
- La **ALU** opera sobre los operandos seleccionados.
- El **multiplicador** opera en paralelo sobre `rs1_data` y `rs2_data` directamente (sin pasar por los MUX de la ALU).

### 5.4 Etapa de Acceso a Memoria (Memory Access)

```
  alu_result ──→ o_dmem_addr    (dirección de memoria = resultado de ALU)
  rs2_data   ──→ o_dmem_wdata   (dato a escribir = rs2)
  ctrl_mem_write → o_dmem_we
  ctrl_mem_read  → o_dmem_re
  i_dmem_rdata ←── dato leído de memoria (a través del address decoder)
```

- La dirección de memoria de datos es siempre el resultado de la ALU (`alu_result`). Para instrucciones Load y Store, la ALU calcula `rs1 + inmediato` (la dirección efectiva).
- El dato a escribir en Store es siempre `rs2_data`.
- Las señales `mem_write` y `mem_read` controlan el acceso y son mutuamente excluyentes (una instrucción nunca lee y escribe memoria simultáneamente).

### 5.5 Etapa de Write-Back

```
                ┌──────────────┐
  alu_result ──→│ d0           │
  dmem_rdata ──→│ d1   MUX    │──→ wb_result_mux ──→┌──────────┐
  pc_plus_4  ──→│ d2  4:1     │                     │ MUX MUL  │──→ wb_data ──→ register_file
  immediate  ──→│ d3           │                     │ d0=ALU/WB│
                │ sel=         │                     │ d1=MUL   │
                │ result_src   │                     │ sel=     │
                └──────────────┘                     │ mul_sel  │
                                                     └──────────┘
```

1. El **MUX de resultado** (`u_mux_result`, 4:1) selecciona entre 4 fuentes según `result_src`.
2. El **MUX del multiplicador** (`u_mux_mul`, 2:1) selecciona entre el resultado normal y el resultado de MUL según `mul_sel`.
3. El dato final (`wb_data`) se escribe en el archivo de registros en la dirección `rd`, siempre que `ctrl_reg_write == 1`.

### 5.6 Lógica de Salto (Branch/Jump)

```
  pc_current ──→┌──────────┐
  immediate  ──→│ Adder    │──→ pc_branch_target (PC + imm)
                └──────────┘
                                    ┌──────────┐
  alu_result ──→ {[31:1], 1'b0} ──→│          │
                                    │ MUX JALR │──→ pc_target
  pc_branch_target ─────────────── →│ sel=jalr │
                                    └──────────┘
                                         │
                                         ↓
                                    ┌──────────┐
  pc_plus_4 ──→                     │ MUX PC   │──→ pc_next ──→ Program Counter
                                    │ sel=     │
                                    │ pc_sel   │
                                    └──────────┘
```

1. **Cálculo del target de Branch/JAL**: `pc_branch_target = pc_current + immediate`. El sumador `u_pc_add_imm` realiza esta operación.
2. **Cálculo del target de JALR**: `pc_jalr_target = {alu_result[31:1], 1'b0}`. Se toma el resultado de la ALU (`rs1 + inmediato`) y se fuerza el bit menos significativo a `0` (alineación a half-word, conforme a la especificación RISC-V).
3. **MUX JALR** (`u_mux_jalr`): selecciona entre `pc_branch_target` (Branch/JAL) y `pc_jalr_target` (JALR) según la señal `ctrl_jalr`.
4. **MUX PC** (`u_mux_pc_next`): selecciona entre `pc_plus_4` (avance normal) y `pc_target` (salto) según la señal `pc_sel` de la unidad de branch.

---

## 6. Periféricos

### 6.1 Decodificador de Direcciones (`addr_decoder.v`)

(Ver [Sección 3.2](#32-lógica-de-decodificación) para la lógica de decodificación detallada.)

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `i_addr` | 32 | Entrada | Dirección del bus de datos |
| `i_mem_we` | 1 | Entrada | Write enable del core |
| `i_mem_re` | 1 | Entrada | Read enable del core |
| `o_cs_dmem` | 1 | Salida | Chip select de RAM |
| `o_cs_gpio` | 1 | Salida | Chip select de GPIO |
| `o_cs_uart` | 1 | Salida | Chip select de UART |
| `i_dmem_rdata` | 32 | Entrada | Dato de lectura de RAM |
| `i_gpio_rdata` | 32 | Entrada | Dato de lectura de GPIO |
| `i_uart_rdata` | 32 | Entrada | Dato de lectura de UART |
| `o_rdata` | 32 | Salida | Dato de lectura multiplexado hacia el core |

---

### 6.2 GPIO (`gpio_peripheral.v`)

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `clk` | 1 | Entrada | Reloj del sistema |
| `rst` | 1 | Entrada | Reset síncrono |
| `i_cs` | 1 | Entrada | Chip select |
| `i_we` | 1 | Entrada | Write enable |
| `i_addr` | 8 | Entrada | Offset del registro |
| `i_wdata` | 32 | Entrada | Dato de escritura |
| `o_rdata` | 32 | Salida | Dato de lectura |
| `o_gpio_out` | 8 | Salida | Pines de salida (LEDs) |
| `i_gpio_in` | 8 | Entrada | Pines de entrada (switches) |

**Registro interno:** `gpio_out_reg[7:0]` — registro de 8 bits conectado a los LEDs.

**Escritura** (síncrona): cuando `i_cs && i_we && i_addr == 8'h24`, se almacena `i_wdata[7:0]` en `gpio_out_reg`.

**Lectura** (combinacional):
- Offset `0x24`: devuelve `{24'b0, gpio_out_reg}` (último valor escrito en LEDs)
- Offset `0x28`: devuelve `{24'b0, i_gpio_in}` (valor actual de los switches)
- Otros offsets: devuelve `32'b0`

---

### 6.3 UART

> **Diagramas interactivos:**
> - [`docs/diagrams/03_uart_system.drawio`](docs/diagrams/03_uart_system.drawio) — Arquitectura interna: FSMs de TX/RX, registros memory-mapped, sincronizador, pines.
> - [`docs/diagrams/05_uart_timing.drawio`](docs/diagrams/05_uart_timing.drawio) — Protocolo de timing 8N1, estrategia center-bit sampling, secuencia de comunicación factorial.

<!-- Descomentar cuando se exporten las imágenes:
![Sistema UART](docs/diagrams/03_uart_system.png)
![Timing UART](docs/diagrams/05_uart_timing.png)
-->

La UART está compuesta por 3 módulos jerárquicos:

#### 6.3.1 Transmisor (`uart_tx.v`)

Máquina de estados de 4 estados que serializa un byte en formato UART: 1 bit de start, 8 bits de datos (LSB primero), 1 bit de stop. Sin paridad.

**Parámetros:**

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| `CLK_FREQ` | `50_000_000` | Frecuencia del reloj (50 MHz) |
| `BAUD_RATE` | `9600` | Velocidad en baudios |

**Constante derivada:**
```
CLKS_PER_BIT = CLK_FREQ / BAUD_RATE = 50,000,000 / 9600 = 5208
```

Cada bit permanece en la línea durante exactamente 5208 ciclos de reloj (≈ 104.16 us).

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `clk` | 1 | Entrada | Reloj del sistema |
| `rst` | 1 | Entrada | Reset síncrono |
| `i_data` | 8 | Entrada | Byte a transmitir |
| `i_start` | 1 | Entrada | Pulso de inicio (1 ciclo) |
| `o_tx` | 1 | Salida | Línea serial TX |
| `o_busy` | 1 | Salida | 1 mientras transmite |

**Registros internos:**
- `state[1:0]`: estado actual de la FSM
- `clk_cnt[15:0]`: contador de ciclos de reloj dentro del bit actual
- `bit_idx[2:0]`: índice del bit de datos actual (0–7)
- `data_reg[7:0]`: dato latched al iniciar la transmisión

**Diagrama de estados:**

```
         ┌──────────────────────────────────────────────────┐
         │                                                  │
         ↓                                                  │
    ┌─────────┐  i_start=1  ┌─────────┐  5208 ciclos  ┌─────────┐
    │  IDLE   │────────────→│  START  │───────────────→│  DATA   │
    │ TX = 1  │             │ TX = 0  │                │TX=d[idx]│
    └─────────┘             └─────────┘                └────┬────┘
         ↑                                                  │
         │                                             bit_idx==7
         │     5208 ciclos  ┌─────────┐  5208 ciclos        │
         └─────────────────←│  STOP   │←────────────────────┘
                            │ TX = 1  │
                            └─────────┘
```

**Cronograma de una transmisión (byte `0x55` = `01010101`):**
```
TX:  ─────┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌───────────
          │ │ │ │ │ │ │ │ │ │
          └─┘ └─┘ └─┘ └─┘ └─┘
          S  0 1 0 1 0 1 0 1  P
          t  (LSB)          (MSB) t
          a                       o
          r                       p
          t
```
Duración total: 10 × 5208 = 52,080 ciclos = ~1.04 ms por byte.

#### 6.3.2 Receptor (`uart_rx.v`)

Máquina de estados que deserializa datos UART con muestreo en el centro de cada bit.

**Parámetros y constantes:** idénticos al transmisor (`CLKS_PER_BIT = 5208`).

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `clk` | 1 | Entrada | Reloj del sistema |
| `rst` | 1 | Entrada | Reset síncrono |
| `i_rx` | 1 | Entrada | Línea serial RX |
| `o_data` | 8 | Salida | Byte recibido |
| `o_valid` | 1 | Salida | Pulso de 1 ciclo indicando dato válido |

**Registros internos:**
- `state[1:0]`: estado actual de la FSM
- `clk_cnt[15:0]`: contador de ciclos
- `bit_idx[2:0]`: índice del bit actual (0–7)
- `data_reg[7:0]`: bits recibidos (acumulación)
- `rx_sync_0`, `rx_sync_1`: sincronizador de doble flip-flop

**Sincronizador anti-metaestabilidad:**

La señal `i_rx` proviene de un dominio de reloj externo (la PC/terminal serial). Para evitar metaestabilidad en el FPGA, se pasa por dos flip-flops en cascada:

```
i_rx ──→ [FF] rx_sync_0 ──→ [FF] rx_sync_1 ──→ (señal sincronizada usada por la FSM)
```

Ambos flip-flops se inicializan en `1` (estado idle de UART) durante el reset.

**Diagrama de estados:**

```
    ┌─────────┐  rx_sync_1=0   ┌─────────┐
    │  IDLE   │────────────────→│  START  │
    │         │                 │         │
    └─────────┘                 └────┬────┘
         ↑                          │
         │                   CLKS_PER_BIT/2
         │                   (centro del start bit)
         │                          │
         │  rx_sync_1=1?            │ rx_sync_1=0?
         │  (falso start) ←── NO ──┤── SI ──→┌─────────┐
         │                                    │  DATA   │
         │                                    │ muestreo│
         │                                    │ al centro│
         │                                    └────┬────┘
         │                                         │
         │                                    bit_idx==7
         │                                         │
         │     o_valid=1    ┌─────────┐            │
         └──────────────────│  STOP   │←───────────┘
              o_data=data   │         │  CLKS_PER_BIT
                            └─────────┘
```

**Estrategia de muestreo:**

1. **Detección del start bit**: cuando `rx_sync_1` cae a `0` estando en IDLE, se transiciona a START.
2. **Verificación del start bit**: se espera `CLKS_PER_BIT / 2 - 1` ciclos para llegar al **centro** del bit de start. Si `rx_sync_1` sigue en `0`, es un start bit válido. Si volvió a `1`, es un glitch y se regresa a IDLE.
3. **Muestreo de datos**: cada `CLKS_PER_BIT` ciclos se muestrea `rx_sync_1` y se almacena en `data_reg[bit_idx]`. El muestreo ocurre en el **centro exacto** de cada bit, maximizando el margen de tolerancia a desviaciones de baudaje.
4. **Bit de stop**: se espera `CLKS_PER_BIT` ciclos adicionales. Al completarse, se activa `o_valid` por un ciclo y se transfiere `data_reg` a `o_data`.

#### 6.3.3 Periférico UART (`uart_peripheral.v`)

Wrapper memory-mapped que integra `uart_tx` y `uart_rx` con una interfaz de bus compatible con el decodificador de direcciones del SoC.

**Puertos:**

| Puerto | Ancho | Dirección | Descripción |
|--------|-------|-----------|-------------|
| `clk` | 1 | Entrada | Reloj del sistema |
| `rst` | 1 | Entrada | Reset síncrono |
| `i_cs` | 1 | Entrada | Chip select |
| `i_we` | 1 | Entrada | Write enable |
| `i_addr` | 8 | Entrada | Offset del registro |
| `i_wdata` | 32 | Entrada | Dato de escritura |
| `o_rdata` | 32 | Salida | Dato de lectura |
| `o_uart_tx` | 1 | Salida | Pin TX físico |
| `i_uart_rx` | 1 | Entrada | Pin RX físico |

**Registros internos:**
- `tx_start`: pulso de 1 ciclo para iniciar transmisión
- `tx_data[7:0]`: byte a transmitir (latched)
- `rx_ready`: bandera de dato disponible
- `rx_data_reg[7:0]`: último byte recibido (latched)

**Lógica de escritura TX** (síncrona):
```
Cada ciclo de reloj:
  tx_start <= 0  (default: no iniciar)
  Si (i_cs AND i_we AND i_addr == 0x30 AND NOT tx_busy):
    tx_data  <= i_wdata[7:0]
    tx_start <= 1  (pulso de inicio)
```

La condición `!tx_busy` actúa como guardia hardware: si el transmisor está ocupado, la escritura es ignorada. El software debe verificar `tx_busy == 0` antes de escribir (ver programa de factorial).

**Lógica de recepción RX** (síncrona):
```
Cada ciclo de reloj:
  Si (rx_valid):
    rx_data_reg <= rx_data    (latch del dato recibido)
    rx_ready    <= 1          (marcar dato como disponible)
  Sino si (i_cs AND NOT i_we AND i_addr == 0x34):
    rx_ready <= 0             (limpiar al leer UART_RX_DATA)
```

Prioridad: si llega un nuevo dato (`rx_valid`) en el mismo ciclo que una lectura de `UART_RX_DATA`, el dato nuevo se almacena y `rx_ready` permanece en `1`. La lectura obtiene el dato anterior (del path combinacional), y el dato nuevo estará disponible en la siguiente lectura.

**Lectura combinacional:**

| Offset | Dato retornado |
|--------|----------------|
| `0x30` (TX_DATA) | `32'b0` (registro de solo escritura) |
| `0x34` (RX_DATA) | `{24'b0, rx_data_reg}` |
| `0x38` (STATUS) | `{30'b0, rx_ready, tx_busy}` |
| Otros | `32'b0` |

**Temporización entre escritura y transmisión:**

| Ciclo | Evento |
|-------|--------|
| N | La instrucción `sw` escribe en `UART_TX_DATA`. El periférico ve `i_cs=1, i_we=1, i_addr=0x30`. |
| N (flanco) | El periférico registra `tx_start <= 1`, `tx_data <= dato`. |
| N+1 | El módulo `uart_tx` ve `i_start = 1` y transiciona de `IDLE` a `START`. |
| N+1 (flanco) | `tx_start <= 0` (el periférico limpia el pulso). `o_busy` se activa (`state != IDLE`). |
| N+1 a N+52080 | Transmisión del frame completo (start + 8 data + stop = 10 bits × 5208 ciclos). |
| N+52081 | `uart_tx` regresa a `IDLE`. `o_busy` se desactiva. |

---

## 7. Programa de Factorial

### 7.1 Algoritmo

```
1. Inicializar punteros a registros UART
2. WAIT_RX: Leer UART_STATUS en bucle hasta que rx_ready == 1
3. Leer UART_RX_DATA → n
4. Calcular factorial:
   resultado = 1
   Si n == 0: resultado = 1 (saltar a SEND)
   Sino: resultado = n × (n-1) × ... × 1
5. SEND: Transmitir resultado en 4 bytes (MSB primero):
   Byte 3: resultado[31:24]
   Byte 2: resultado[23:16]
   Byte 1: resultado[15:8]
   Byte 0: resultado[7:0]
   Para cada byte: esperar tx_busy == 0, luego escribir en UART_TX_DATA
6. Volver al paso 2
```

### 7.2 Uso de Registros

| Registro | ABI | Uso en el programa |
|----------|-----|--------------------|
| `x8` | `s0` | Base de periféricos: `0x10010000` |
| `x9` | `s1` | Puntero a `UART_TX_DATA`: `0x10010030` |
| `x18` | `s2` | Puntero a `UART_RX_DATA`: `0x10010034` |
| `x19` | `s3` | Puntero a `UART_STATUS`: `0x10010038` |
| `x10` | `a0` | Valor de `n` (contador descendente en el bucle factorial) |
| `x11` | `a1` | Acumulador del resultado (`n!`) |
| `x12` | `a2` | Byte a transmitir (extraído del resultado) |
| `x5` | `t0` | Temporal para lectura de status |

### 7.3 Código Ensamblador con Codificación Máquina

Cada instrucción se lista con su dirección de PC, dirección de palabra en la ROM, codificación hexadecimal, mnemónico y descripción.

```
PC          Word  Hex         Instrucción                     Descripción
──────────  ────  ──────────  ──────────────────────────────  ──────────────────────────────
0x00400000   0    0x0FC10417  auipc s0, 0xFC10                s0 = PC + 0x0FC10000 = 0x10010000
0x00400004   1    0x03040493  addi  s1, s0, 0x030             s1 = 0x10010030 (UART_TX_DATA)
0x00400008   2    0x03440913  addi  s2, s0, 0x034             s2 = 0x10010034 (UART_RX_DATA)
0x0040000C   3    0x03840993  addi  s3, s0, 0x038             s3 = 0x10010038 (UART_STATUS)

                              WAIT_RX:
0x00400010   4    0x0009A283  lw    t0, 0(s3)                 t0 = UART_STATUS
0x00400014   5    0x0022F293  andi  t0, t0, 2                 Aislar bit 1 (rx_ready)
0x00400018   6    0xFE028CE3  beq   t0, zero, WAIT_RX         Si rx_ready==0, volver a leer

0x0040001C   7    0x00092503  lw    a0, 0(s2)                 a0 = n (limpia rx_ready)
0x00400020   8    0x00100593  addi  a1, zero, 1               a1 = 1 (acumulador)
0x00400024   9    0x00050863  beq   a0, zero, SEND            Si n==0, saltar a SEND

                              FACT_LOOP:
0x00400028  10    0x02A585B3  mul   a1, a1, a0                a1 = a1 * a0
0x0040002C  11    0xFFF50513  addi  a0, a0, -1                a0 = a0 - 1
0x00400030  12    0xFE051CE3  bne   a0, zero, FACT_LOOP       Si a0 != 0, repetir

                              SEND:
0x00400034  13    0x0185D613  srli  a2, a1, 24                a2 = resultado >> 24 (byte 3)
                              WAIT_TX_3:
0x00400038  14    0x0009A283  lw    t0, 0(s3)                 t0 = UART_STATUS
0x0040003C  15    0x0012F293  andi  t0, t0, 1                 Aislar bit 0 (tx_busy)
0x00400040  16    0xFE029CE3  bne   t0, zero, WAIT_TX_3       Esperar si tx_busy==1
0x00400044  17    0x00C4A023  sw    a2, 0(s1)                 Transmitir byte 3

0x00400048  18    0x0105D613  srli  a2, a1, 16                a2 = resultado >> 16
0x0040004C  19    0x0FF67613  andi  a2, a2, 0xFF              Enmascarar a 8 bits (byte 2)
                              WAIT_TX_2:
0x00400050  20    0x0009A283  lw    t0, 0(s3)                 t0 = UART_STATUS
0x00400054  21    0x0012F293  andi  t0, t0, 1                 tx_busy?
0x00400058  22    0xFE029CE3  bne   t0, zero, WAIT_TX_2       Esperar
0x0040005C  23    0x00C4A023  sw    a2, 0(s1)                 Transmitir byte 2

0x00400060  24    0x0085D613  srli  a2, a1, 8                 a2 = resultado >> 8
0x00400064  25    0x0FF67613  andi  a2, a2, 0xFF              Enmascarar (byte 1)
                              WAIT_TX_1:
0x00400068  26    0x0009A283  lw    t0, 0(s3)                 t0 = UART_STATUS
0x0040006C  27    0x0012F293  andi  t0, t0, 1                 tx_busy?
0x00400070  28    0xFE029CE3  bne   t0, zero, WAIT_TX_1       Esperar
0x00400074  29    0x00C4A023  sw    a2, 0(s1)                 Transmitir byte 1

0x00400078  30    0x0FF5F613  andi  a2, a1, 0xFF              a2 = resultado & 0xFF (byte 0)
                              WAIT_TX_0:
0x0040007C  31    0x0009A283  lw    t0, 0(s3)                 t0 = UART_STATUS
0x00400080  32    0x0012F293  andi  t0, t0, 1                 tx_busy?
0x00400084  33    0xFE029CE3  bne   t0, zero, WAIT_TX_0       Esperar
0x00400088  34    0x00C4A023  sw    a2, 0(s1)                 Transmitir byte 0

0x0040008C  35    0xF85FF06F  jal   zero, WAIT_RX             Saltar a WAIT_RX (offset -124)
```

### 7.4 Cálculo de la Dirección Base (`auipc`)

La primera instrucción (`auipc s0, 0xFC10`) calcula la dirección base del espacio de periféricos:

```
s0 = PC + (0x0FC10 << 12)
   = 0x00400000 + 0x0FC10000
   = 0x10010000
```

Este valor (`0x10010000`) es la base del espacio de periféricos definido por el decodificador de direcciones (`i_addr[31:16] == 16'h1001`).

### 7.5 Traza del Factorial para n = 5

| Iteración | `a0` (n) | `a1` (resultado) | Operación |
|:---------:|:--------:|:-----------------:|-----------|
| Inicio | 5 | 1 | `a0 = n`, `a1 = 1` |
| 1 | 4 | 5 | `a1 = 1 × 5 = 5`, `a0 = 5 - 1 = 4` |
| 2 | 3 | 20 | `a1 = 5 × 4 = 20`, `a0 = 4 - 1 = 3` |
| 3 | 2 | 60 | `a1 = 20 × 3 = 60`, `a0 = 3 - 1 = 2` |
| 4 | 1 | 120 | `a1 = 60 × 2 = 120`, `a0 = 2 - 1 = 1` |
| 5 | 0 | 120 | `a1 = 120 × 1 = 120`, `a0 = 1 - 1 = 0` (sale del bucle) |

Resultado: `120 = 0x00000078`

Bytes transmitidos (MSB primero): `0x00`, `0x00`, `0x00`, `0x78`

### 7.6 Valores de Referencia de Factorial

| n | n! (decimal) | n! (hexadecimal) | Bytes TX (MSB primero) |
|:-:|:------------:|:-----------------:|:----------------------:|
| 0 | 1 | `0x00000001` | `00 00 00 01` |
| 1 | 1 | `0x00000001` | `00 00 00 01` |
| 2 | 2 | `0x00000002` | `00 00 00 02` |
| 3 | 6 | `0x00000006` | `00 00 00 06` |
| 4 | 24 | `0x00000018` | `00 00 00 18` |
| 5 | 120 | `0x00000078` | `00 00 00 78` |
| 6 | 720 | `0x000002D0` | `00 00 02 D0` |
| 7 | 5040 | `0x000013B0` | `00 00 13 B0` |
| 8 | 40320 | `0x00009D80` | `00 00 9D 80` |
| 9 | 362880 | `0x00058980` | `00 05 89 80` |
| 10 | 3628800 | `0x00375F00` | `00 37 5F 00` |
| 11 | 39916800 | `0x02611500` | `02 61 15 00` |
| 12 | 479001600 | `0x1C8CFC00` | `1C 8C FC 00` |
| >12 | Overflow | — | Resultado truncado a 32 bits |

---

## 8. Conjunto de Instrucciones Soportadas

### 8.1 Base Integer (RV32I) — 38 instrucciones

#### Aritmética y Lógica (14)

| Instrucción | Tipo | Formato | funct3 | funct7 | Operación |
|-------------|------|---------|:------:|:------:|-----------|
| `ADD rd, rs1, rs2` | R | `0110011` | `000` | `0000000` | `rd = rs1 + rs2` |
| `SUB rd, rs1, rs2` | R | `0110011` | `000` | `0100000` | `rd = rs1 - rs2` |
| `AND rd, rs1, rs2` | R | `0110011` | `111` | `0000000` | `rd = rs1 & rs2` |
| `OR rd, rs1, rs2` | R | `0110011` | `110` | `0000000` | `rd = rs1 \| rs2` |
| `XOR rd, rs1, rs2` | R | `0110011` | `100` | `0000000` | `rd = rs1 ^ rs2` |
| `SLL rd, rs1, rs2` | R | `0110011` | `001` | `0000000` | `rd = rs1 << rs2[4:0]` |
| `SRL rd, rs1, rs2` | R | `0110011` | `101` | `0000000` | `rd = rs1 >> rs2[4:0]` (lógico) |
| `SRA rd, rs1, rs2` | R | `0110011` | `101` | `0100000` | `rd = rs1 >>> rs2[4:0]` (aritmético) |
| `SLT rd, rs1, rs2` | R | `0110011` | `010` | `0000000` | `rd = (rs1 < rs2) ? 1 : 0` (con signo) |
| `SLTU rd, rs1, rs2` | R | `0110011` | `011` | `0000000` | `rd = (rs1 < rs2) ? 1 : 0` (sin signo) |
| `ADDI rd, rs1, imm` | I | `0010011` | `000` | — | `rd = rs1 + sext(imm)` |
| `ANDI rd, rs1, imm` | I | `0010011` | `111` | — | `rd = rs1 & sext(imm)` |
| `ORI rd, rs1, imm` | I | `0010011` | `110` | — | `rd = rs1 \| sext(imm)` |
| `XORI rd, rs1, imm` | I | `0010011` | `100` | — | `rd = rs1 ^ sext(imm)` |

#### Shifts con Inmediato (3)

| Instrucción | Tipo | Formato | funct3 | imm[11:5] | Operación |
|-------------|------|---------|:------:|:---------:|-----------|
| `SLLI rd, rs1, shamt` | I | `0010011` | `001` | `0000000` | `rd = rs1 << shamt` |
| `SRLI rd, rs1, shamt` | I | `0010011` | `101` | `0000000` | `rd = rs1 >> shamt` (lógico) |
| `SRAI rd, rs1, shamt` | I | `0010011` | `101` | `0100000` | `rd = rs1 >>> shamt` (aritmético) |

#### Comparación con Inmediato (2)

| Instrucción | Tipo | Formato | funct3 | Operación |
|-------------|------|---------|:------:|-----------|
| `SLTI rd, rs1, imm` | I | `0010011` | `010` | `rd = (rs1 < sext(imm)) ? 1 : 0` (con signo) |
| `SLTIU rd, rs1, imm` | I | `0010011` | `011` | `rd = (rs1 < sext(imm)) ? 1 : 0` (sin signo) |

#### Load/Store (2 implementadas: palabra completa)

| Instrucción | Tipo | Formato | funct3 | Operación |
|-------------|------|---------|:------:|-----------|
| `LW rd, imm(rs1)` | I | `0000011` | `010` | `rd = mem[rs1 + sext(imm)]` |
| `SW rs2, imm(rs1)` | S | `0100011` | `010` | `mem[rs1 + sext(imm)] = rs2` |

#### Branch (6)

| Instrucción | Tipo | Formato | funct3 | Condición |
|-------------|------|---------|:------:|-----------|
| `BEQ rs1, rs2, offset` | B | `1100011` | `000` | `rs1 == rs2` |
| `BNE rs1, rs2, offset` | B | `1100011` | `001` | `rs1 != rs2` |
| `BLT rs1, rs2, offset` | B | `1100011` | `100` | `$signed(rs1) < $signed(rs2)` |
| `BGE rs1, rs2, offset` | B | `1100011` | `101` | `$signed(rs1) >= $signed(rs2)` |
| `BLTU rs1, rs2, offset` | B | `1100011` | `110` | `rs1 < rs2` (sin signo) |
| `BGEU rs1, rs2, offset` | B | `1100011` | `111` | `rs1 >= rs2` (sin signo) |

#### Upper Immediate (2)

| Instrucción | Tipo | Formato | Operación |
|-------------|------|---------|-----------|
| `LUI rd, imm` | U | `0110111` | `rd = imm << 12` |
| `AUIPC rd, imm` | U | `0010111` | `rd = PC + (imm << 12)` |

#### Saltos (2)

| Instrucción | Tipo | Formato | Operación |
|-------------|------|---------|-----------|
| `JAL rd, offset` | J | `1101111` | `rd = PC + 4; PC = PC + sext(offset)` |
| `JALR rd, rs1, imm` | I | `1100111` | `rd = PC + 4; PC = (rs1 + sext(imm)) & ~1` |

### 8.2 Extensión Multiplicación (RV32M parcial) — 1 instrucción

| Instrucción | Tipo | Formato | funct3 | funct7 | Operación |
|-------------|------|---------|:------:|:------:|-----------|
| `MUL rd, rs1, rs2` | R | `0110011` | `000` | `0000001` | `rd = (rs1 × rs2)[31:0]` |

---

## 9. Pinout DE10-Standard (Cyclone V 5CSXFC6D6F31C6N)

Referencia: DE10-Standard User Manual, Tablas 3-6 (SW), 3-8 (LEDR), 3-11 (GPIO). Todos los pines usan I/O standard **3.3-V LVTTL**.

| Señal del SoC | Pin FPGA | Componente de la tarjeta | Dirección |
|----------------|----------|--------------------------|-----------|
| `clk` | `PIN_AF14` | CLOCK_50 (50 MHz) | Entrada |
| `rst` | `PIN_AA30` | SW[9] | Entrada |
| `o_uart_tx` | `PIN_W15` | GPIO_0[0] | Salida |
| `i_uart_rx` | `PIN_AK2` | GPIO_0[1] | Entrada |
| `o_gpio_out[0]` | `PIN_AA24` | LEDR[0] | Salida |
| `o_gpio_out[1]` | `PIN_AB23` | LEDR[1] | Salida |
| `o_gpio_out[2]` | `PIN_AC23` | LEDR[2] | Salida |
| `o_gpio_out[3]` | `PIN_AD24` | LEDR[3] | Salida |
| `o_gpio_out[4]` | `PIN_AG25` | LEDR[4] | Salida |
| `o_gpio_out[5]` | `PIN_AF25` | LEDR[5] | Salida |
| `o_gpio_out[6]` | `PIN_AE24` | LEDR[6] | Salida |
| `o_gpio_out[7]` | `PIN_AF24` | LEDR[7] | Salida |
| `i_gpio_in[0]` | `PIN_AB30` | SW[0] | Entrada |
| `i_gpio_in[1]` | `PIN_Y27` | SW[1] | Entrada |
| `i_gpio_in[2]` | `PIN_AB28` | SW[2] | Entrada |
| `i_gpio_in[3]` | `PIN_AC30` | SW[3] | Entrada |
| `i_gpio_in[4]` | `PIN_W25` | SW[4] | Entrada |
| `i_gpio_in[5]` | `PIN_V25` | SW[5] | Entrada |
| `i_gpio_in[6]` | `PIN_AC28` | SW[6] | Entrada |
| `i_gpio_in[7]` | `PIN_AD30` | SW[7] | Entrada |

**Configuración de la UART:**
- Baudios: 9600
- Bits de datos: 8
- Paridad: Ninguna
- Bits de stop: 1
- Control de flujo: Ninguno

**Terminal serial recomendada:** Docklight (o cualquier terminal capaz de transmitir valores hexadecimales directamente).

---

## 10. Simulación

### 10.1 Testbench del SoC (`soc_uart_factorial_tb.v`)

El testbench simula el sistema completo: envía un byte por UART RX, espera que el procesador calcule el factorial, y captura los 4 bytes transmitidos por UART TX.

**Casos de prueba incluidos:**

| Test | Entrada (n) | Resultado esperado | Bytes TX esperados |
|:----:|:-----------:|:------------------:|:------------------:|
| 1 | 5 | 120 (`0x00000078`) | `00 00 00 78` |
| 2 | 1 | 1 (`0x00000001`) | `00 00 00 01` |
| 3 | 10 | 3628800 (`0x00375F00`) | `00 37 5F 00` |

**Tareas del testbench:**

- `send_byte(data)`: genera una trama UART completa (start + 8 data + stop) en el pin `uart_rx_pin` a 9600 baud. Usa `repeat(CLKS_PER_BIT) @(posedge clk)` para temporización precisa sincronizada al reloj.

- `receive_byte(data)`: espera el flanco de bajada en `uart_tx_pin` (start bit), avanza al centro del bit, y muestrea 8 bits de datos a intervalos de `CLKS_PER_BIT`. Retorna el byte recibido.

**Tiempo de simulación estimado:**

- Cada byte UART (10 bits × 5208 ciclos × 20 ns) ≈ 1.04 ms
- Recepción de 1 byte + cómputo + transmisión de 4 bytes ≈ 5.2 ms por test
- 3 tests ≈ 15.6 ms
- Timeout de seguridad: 30 ms

### 10.2 Ejecución en ModelSim/Questa

```
# Compilar core
vlog rtl/core/adder_4_32b/source/adder_4_32b.v
vlog rtl/core/program_counter/source/program_counter.v
vlog rtl/core/register_file/source/register_file.v
vlog rtl/core/alu_riscv_rv32i/source/alu_riscv_rv32i.v
vlog rtl/core/mul_module/source/mul_module.v
vlog rtl/core/mux_2i_1o/source/mux_2i_1o.v
vlog rtl/core/mux_4i_1o/source/mux_4i_1o.v
vlog rtl/core/main_control_rv32i/source/main_control_rv32i.v
vlog rtl/core/control_alu_rv32i/source/control_alu_rv32i.v
vlog rtl/core/imm_generator/source/imm_generator.v
vlog rtl/core/branch_unit/source/branch_unit.v
vlog rtl/core/rv32i_single_cycle/source/rv32i_single_cycle.v

# Compilar memorias
vlog rtl/memory/data_memory/source/data_memory.v
vlog rtl/memory/rom_combinational_sc/source/rom_combinational_sc.v

# Compilar perifericos
vlog rtl/peripherals/addr_decoder/source/addr_decoder.v
vlog rtl/peripherals/gpio_peripheral/source/gpio_peripheral.v
vlog rtl/peripherals/uart_tx/source/uart_tx.v
vlog rtl/peripherals/uart_rx/source/uart_rx.v
vlog rtl/peripherals/uart_peripheral/source/uart_peripheral.v

# Compilar SoC y testbench
vlog rtl/soc/soc_rv32i_single_cycle/source/soc_rv32i_single_cycle.v
vlog rtl/soc/soc_rv32i_single_cycle/questa_project/soc_uart_factorial_tb.v

# Simular
vsim -c soc_uart_factorial_tb -do "run -all"
```

**Alternativa rapida:** Usar el script `.do` preconfigurado:
```
cd rtl/soc/soc_rv32i_single_cycle/questa_project/
vsim -do run_tb.do
```

---

## 11. Notas de Diseño

### 11.1 Arquitectura Single-Cycle

En una arquitectura single-cycle, cada instrucción se ejecuta completamente en un único ciclo de reloj. Esto significa que:

- El período del reloj debe ser lo suficientemente largo para acomodar el **camino crítico** más largo (típicamente una instrucción Load: Fetch → Decode → Execute → Memory → Write-back).
- No existe hazard de datos ni de control porque cada instrucción comienza y termina en el mismo ciclo.
- No se requiere forwarding, stalling, ni predicción de branches.
- La frecuencia máxima está limitada por la instrucción más lenta.

### 11.2 Diseño Estructural vs Comportamental

Conforme a los requisitos del profesor:
- El **SoC** y el **core del procesador** (`soc_rv32i_single_cycle.v` y `rv32i_single_cycle.v`) son **diseños estructurales**: solo instancian submódulos y los conectan con cables. No contienen `always` blocks ni lógica comportamental.
- Los **módulos constitutivos** (ALU, control, registro, memorias, UART) son **implementaciones comportamentales**: usan `always @(*)`, `always @(posedge clk)`, `case` statements, y operadores aritméticos.

### 11.3 Convenciones del Código

- **Timescale**: todos los módulos usan `` `timescale 1ns/1ps ``
- **Reset**: síncrono, activo en alto
- **Nomenclatura de puertos**: prefijo `i_` para entradas, `o_` para salidas
- **Parámetros**: `UPPER_CASE`
- **Señales internas**: `lower_case` con guiones bajos
- **Direccionamiento RARS**: PC comienza en `0x0040_0000`, datos en `0x1001_0000`

### 11.4 Limitaciones Conocidas

1. **Solo acceso a palabra completa (32 bits)**: las instrucciones `LH`, `LB`, `SH`, `SB` no tienen soporte de alineación a byte/half-word en el hardware de memoria actual. El programa de factorial solo usa `LW`/`SW`.
2. **Sin pipeline**: CPI (Cycles Per Instruction) = 1, pero la frecuencia máxima es menor que un diseño pipelined.
3. **ROM hardcoded**: el programa está codificado directamente en el `case` statement de la ROM. Para cambiar el programa, se modifica el archivo Verilog.
4. **UART sin FIFO**: solo almacena el último byte recibido. Si llega un segundo byte antes de leer el primero, el primero se pierde.
5. **Overflow en factorial**: para `n > 12`, el resultado excede 32 bits y se trunca.

---

## 12. Diagramas

El proyecto incluye 5 diagramas profesionales en formato **draw.io** (`.drawio`) ubicados en [`docs/diagrams/`](docs/diagrams/). Estos archivos son XML editables que pueden abrirse y modificarse de varias formas:

### Como abrir y editar los diagramas

| Metodo | Instrucciones |
|--------|--------------|
| **VS Code** | Instalar la extension [Draw.io Integration](https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio). Los archivos `.drawio` se abren directamente en el editor con interfaz grafica completa. |
| **draw.io Web** | Ir a [app.diagrams.net](https://app.diagrams.net/) → File → Open from → Device → seleccionar el archivo `.drawio`. |
| **draw.io Desktop** | Descargar desde [github.com/jgraph/drawio-desktop](https://github.com/jgraph/drawio-desktop/releases) y abrir el archivo directamente. |

### Como exportar a imagen (PNG/SVG)

Para incluir las imagenes renderizadas en el README:

1. Abrir el `.drawio` en cualquiera de los metodos anteriores
2. **File → Export as → PNG** (o SVG)
3. Guardar en `docs/diagrams/` con el mismo nombre base (ej: `01_soc_architecture.png`)
4. Descomentar las lineas `![...](docs/diagrams/...)` en este README

### Indice de diagramas

| # | Archivo | Contenido |
|---|---------|-----------|
| 1 | [`01_soc_architecture.drawio`](docs/diagrams/01_soc_architecture.drawio) | Arquitectura general del SoC: core RV32I, ROM, RAM, address decoder, GPIO, UART, buses de instrucciones y datos, pines externos, leyenda de colores por tipo de modulo |
| 2 | [`02_rv32i_datapath.drawio`](docs/diagrams/02_rv32i_datapath.drawio) | Datapath detallado del core: 5 etapas (Fetch→Decode→Execute→Memory→Write-Back), PC con MUX 4:1, register file, ALU + MUL, branch unit, senales de control por tipo de instruccion, logica de Next PC |
| 3 | [`03_uart_system.drawio`](docs/diagrams/03_uart_system.drawio) | Sistema UART completo: uart_peripheral wrapper con mapa de registros (TX_DATA/RX_DATA/STATUS), FSM de 4 estados del transmisor, FSM del receptor con sincronizador double flip-flop, parametros de timing |
| 4 | [`04_memory_map.drawio`](docs/diagrams/04_memory_map.drawio) | Mapa de memoria: espacio de direcciones de 32 bits, regiones ROM/RAM/perifericos, logica de decodificacion en Verilog, registros GPIO y UART con offsets, MUX de lectura con prioridades, calculo AUIPC |
| 5 | [`05_uart_timing.drawio`](docs/diagrams/05_uart_timing.drawio) | Protocolo UART: trama 8N1 con timing por bit, estrategia center-bit sampling del receptor, sincronizador anti-metaestabilidad, diagrama de secuencia factorial(5), tabla de parametros de baud rate |

---

## Información del Proyecto

| Campo | Valor |
|-------|-------|
| **Autor** | Angel Habid Navarro Mendez |
| **Profesor** | Dr. Jose Luis Pizano Escalante |
| **Programa** | Maestria en Diseno Electronico |
| **Institución** | Instituto Tecnológico y de Estudios Superiores de Occidente (ITESO) |
| **Tarjeta FPGA** | Terasic DE10-Standard (Intel Cyclone V 5CSXFC6D6F31C6N) |
| **Herramientas** | Quartus Prime (síntesis), ModelSim/Questa (simulación), RARS (ensamblador) |
