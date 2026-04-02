/***********************************************************
 * Descripcion:
 *   Core RISC-V RV32I Single-Cycle. Contiene el datapath
 *   y la unidad de control. Las memorias se conectan
 *   externamente a traves de los puertos de bus,
 *   permitiendo integrar perifericos en el SoC.
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

module rv32i_single_cycle #(
    parameter RESET_VECTOR = 32'h0000_0000
)(
    input  wire        clk,
    input  wire        rst,

    // --- Bus de instrucciones (Instruction Fetch) ---
    output wire [31:0] o_imem_addr,       // Direccion hacia la ROM (PC)
    input  wire [31:0] i_imem_rdata,      // Instruccion leida de la ROM

    // --- Bus de datos (Load/Store) ---
    output wire [31:0] o_dmem_addr,       // Direccion hacia memoria de datos
    output wire [31:0] o_dmem_wdata,      // Dato a escribir (Store)
    output wire        o_dmem_we,         // Write enable
    output wire        o_dmem_re,         // Read enable
    input  wire [31:0] i_dmem_rdata       // Dato leido (Load)
);

    // ========================================================================
    // Senales internas
    // ========================================================================

    // --- Busqueda de instruccion ---
    wire [31:0] pc_current;
    wire [31:0] pc_plus_4;
    wire [31:0] instruction;

    // --- Decode: campos de la instruccion ---
    wire [6:0]  opcode    = instruction[6:0];
    wire [4:0]  rd        = instruction[11:7];
    wire [2:0]  funct3    = instruction[14:12];
    wire [4:0]  rs1_addr  = instruction[19:15];
    wire [4:0]  rs2_addr  = instruction[24:20];
    wire        funct7_5  = instruction[30];
    wire        funct7_0  = instruction[25];
    wire        op5       = instruction[5];

    // --- Senales de control ---
    wire        ctrl_reg_write;
    wire [1:0]  ctrl_result_src;
    wire        ctrl_mem_write;
    wire        ctrl_mem_read;
    wire        ctrl_branch;
    wire        ctrl_jump;
    wire        ctrl_jalr;
    wire [1:0]  ctrl_alu_op;
    wire        ctrl_alu_src;
    wire        ctrl_alu_a_src;

    // --- ALU Control ---
    wire [3:0]  alu_ctrl;
    wire        mul_sel;

    // --- Register File ---
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // --- Inmediato ---
    wire [31:0] immediate;

    // --- ALU ---
    wire [31:0] alu_input_a;
    wire [31:0] alu_input_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    // --- Multiplicador ---
    wire [31:0] mul_result;

    // --- Write-back ---
    wire [31:0] wb_result_mux;
    wire [31:0] wb_data;

    // --- Branch/Jump ---
    wire        pc_sel;
    wire [31:0] pc_branch_target;
    wire [31:0] pc_jalr_target;
    wire [31:0] pc_target;
    wire [31:0] pc_next;

    // ========================================================================
    // Conexion de buses externos
    // ========================================================================

    assign o_imem_addr  = pc_current;
    assign instruction  = i_imem_rdata;

    assign o_dmem_addr  = alu_result;
    assign o_dmem_wdata = rs2_data;
    assign o_dmem_we    = ctrl_mem_write;
    assign o_dmem_re    = ctrl_mem_read;

    // ========================================================================
    // ETAPA DE BUSQUEDA DE INSTRUCCION
    // ========================================================================

    // --- Program Counter ---
    program_counter #(
        .WIDTH        (32),
        .RESET_VECTOR (RESET_VECTOR)
    ) u_pc (
        .clk       (clk),
        .rst       (rst),
        .en        (1'b1),
        .i_next_pc (pc_next),
        .o_pc      (pc_current)
    );

    // --- PC + 4 ---
    adder_4_32b u_pc_add4 (
        .i_a   (pc_current),
        .i_b   (32'd4),
        .o_sum (pc_plus_4)
    );

    // ========================================================================
    // ETAPA DE DECODIFICACION
    // ========================================================================

    // --- Main Control Unit ---
    main_control_rv32i u_main_ctrl (
        .i_opcode    (opcode),
        .o_reg_write (ctrl_reg_write),
        .o_result_src(ctrl_result_src),
        .o_mem_write (ctrl_mem_write),
        .o_mem_read  (ctrl_mem_read),
        .o_branch    (ctrl_branch),
        .o_jump      (ctrl_jump),
        .o_jalr      (ctrl_jalr),
        .o_alu_op    (ctrl_alu_op),
        .o_alu_src   (ctrl_alu_src),
        .o_alu_a_src (ctrl_alu_a_src)
    );

    // --- ALU Control Unit ---
    control_alu_rv32i u_alu_ctrl (
        .i_alu_op   (ctrl_alu_op),
        .i_funct3   (funct3),
        .i_funct7_5 (funct7_5),
        .i_funct7_0 (funct7_0),
        .i_op5      (op5),
        .o_alu_ctrl (alu_ctrl),
        .o_mul_sel  (mul_sel)
    );

    // --- Immediate Generator ---
    imm_generator u_imm_gen (
        .i_instr (instruction),
        .o_imm   (immediate)
    );

    // --- Register File ---
    register_file u_reg_file (
        .clk      (clk),
        .i_we     (ctrl_reg_write),
        .i_rd     (rd),
        .i_wdata  (wb_data),
        .i_rs1    (rs1_addr),
        .o_rdata1 (rs1_data),
        .i_rs2    (rs2_addr),
        .o_rdata2 (rs2_data)
    );

    // ========================================================================
    // ETAPA DE EJECUCION
    // ========================================================================

    // --- MUX ALU Operando A: rs1 (0) o PC (1) ---
    mux_2i_1o u_mux_alu_a (
        .i_d0  (rs1_data),
        .i_d1  (pc_current),
        .i_sel (ctrl_alu_a_src),
        .o_out (alu_input_a)
    );

    // --- MUX ALU Operando B: rs2 (0) o inmediato (1) ---
    mux_2i_1o u_mux_alu_b (
        .i_d0  (rs2_data),
        .i_d1  (immediate),
        .i_sel (ctrl_alu_src),
        .o_out (alu_input_b)
    );

    // --- ALU ---
    alu_riscv_rv32i u_alu (
        .i_a        (alu_input_a),
        .i_b        (alu_input_b),
        .i_alu_ctrl (alu_ctrl),
        .o_result   (alu_result),
        .o_zero     (alu_zero)
    );

    // --- Multiplicador (extension RV32M: MUL) ---
    mul_module u_mul (
        .i_a      (rs1_data),
        .i_b      (rs2_data),
        .o_result (mul_result)
    );

    // ========================================================================
    // ETAPA DE WRITE-BACK
    // ========================================================================

    // --- MUX de resultado (4 fuentes) ---
    //   00: Resultado ALU  (R, I-ALU, AUIPC)
    //   01: Dato de memoria (Load)
    //   10: PC+4            (JAL, JALR — link address)
    //   11: Inmediato       (LUI)
    mux_4i_1o u_mux_result (
        .i_d0  (alu_result),
        .i_d1  (i_dmem_rdata),
        .i_d2  (pc_plus_4),
        .i_d3  (immediate),
        .i_sel (ctrl_result_src),
        .o_out (wb_result_mux)
    );

    // --- MUX multiplicador: selecciona resultado ALU/WB o MUL ---
    mux_2i_1o u_mux_mul (
        .i_d0  (wb_result_mux),
        .i_d1  (mul_result),
        .i_sel (mul_sel),
        .o_out (wb_data)
    );

    // ========================================================================
    // BRANCH / JUMP — LOGICA DEL SIGUIENTE PC
    // ========================================================================

    // --- Branch Unit: evalua condicion de branch y jump ---
    branch_unit u_branch (
        .i_rs1_data (rs1_data),
        .i_rs2_data (rs2_data),
        .i_funct3   (funct3),
        .i_branch   (ctrl_branch),
        .i_jump     (ctrl_jump),
        .o_pc_sel   (pc_sel)
    );

    // --- PC + inmediato (target de branch y JAL) ---
    adder_4_32b u_pc_add_imm (
        .i_a   (pc_current),
        .i_b   (immediate),
        .o_sum (pc_branch_target)
    );

    // --- JALR target: resultado de ALU con LSB forzado a 0 ---
    assign pc_jalr_target = {alu_result[31:1], 1'b0};

    // --- MUX target: branch/JAL (0) o JALR (1) ---
    mux_2i_1o u_mux_jalr (
        .i_d0  (pc_branch_target),
        .i_d1  (pc_jalr_target),
        .i_sel (ctrl_jalr),
        .o_out (pc_target)
    );

    // --- MUX next PC: PC+4 (0) o target de salto (1) ---
    mux_2i_1o u_mux_pc_next (
        .i_d0  (pc_plus_4),
        .i_d1  (pc_target),
        .i_sel (pc_sel),
        .o_out (pc_next)
    );

endmodule
