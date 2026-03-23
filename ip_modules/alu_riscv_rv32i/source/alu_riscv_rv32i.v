// ============================================================================
// Module:      alu_riscv_rv32i
// Description: Arithmetic Logic Unit (ALU) for a RISC-V RV32I Single-Cycle
//              processor. Implements all integer computational operations
//              defined in the RV32I Base Integer Instruction Set (Vol. I,
//              Chapter 2 of the RISC-V ISA Specification).
//
// Design:      Purely combinational logic (no clock, no state elements).
//              All outputs are resolved within the same clock cycle that
//              the inputs are presented.
//
// Parameters:  WIDTH - Data path width in bits (default: 32 for RV32I)
//
// Port Map:
//   i_a        [WIDTH-1:0] - First operand  (rs1 or PC, depending on instr.)
//   i_b        [WIDTH-1:0] - Second operand (rs2 or immediate, depending on instr.)
//   i_alu_ctrl [3:0]       - Operation selector from ALU Control unit
//   o_result   [WIDTH-1:0] - Computation result
//   o_zero     [0:0]       - Zero flag (1 when o_result == 0)
//
// ALU Control Encoding:
//   4'b0000 -> AND   |  4'b0101 -> SRL   |  4'b1001 -> SLT
//   4'b0001 -> OR    |  4'b0110 -> SUB   |  4'b1010 -> SLTU
//   4'b0010 -> ADD   |  4'b0111 -> SLL   |
//   4'b0100 -> XOR   |  4'b1000 -> SRA   |
//
// RV32I Coverage:
//   - R-type:  ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
//   - I-type:  ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU
//   - Load/Store address calc: base + offset via ADD
//   - Branches: BEQ/BNE via SUB + o_zero,
//               BLT/BGE via SLT, BLTU/BGEU via SLTU
//   - LUI/AUIPC/JAL/JALR: address calc via ADD
// ============================================================================

module alu_riscv_rv32i #(
    parameter WIDTH = 32    // Data path width (32 bits for RV32I)
)(
    // --- Data Inputs ---
    input  wire [WIDTH-1:0]  i_a,           // Operand A (typically rs1 or PC)
    input  wire [WIDTH-1:0]  i_b,           // Operand B (typically rs2 or immediate)

    // --- Control Input ---
    input  wire [3:0]        i_alu_ctrl,    // Operation select from ALU Control unit

    // --- Outputs ---
    output reg  [WIDTH-1:0]  o_result,      // ALU computation result
    output wire              o_zero         // Zero flag: 1 if o_result == 0
);

    // ========================================================================
    // Zero Flag Generation
    // ------------------------------------------------------------------------
    // Continuous assignment: o_zero is HIGH when the result is exactly zero.
    // Used by the branch logic for BEQ (o_zero == 1) and BNE (o_zero == 0).
    // ========================================================================
    assign o_zero = (o_result == {WIDTH{1'b0}});

    // ========================================================================
    // ALU Operation Multiplexer - Purely Combinational
    // ------------------------------------------------------------------------
    // Selects the operation based on the 4-bit control signal i_alu_ctrl.
    // The always @(*) block ensures no latches are inferred, as all paths
    // (including default) assign a value to o_result.
    //
    // Note on shifts: Only the lower 5 bits of i_b (i_b[4:0]) are used as
    // the shift amount, per the RV32I specification (shamt is 5 bits wide
    // for a 32-bit data path).
    //
    // Note on SRA: $signed(i_a) is required so that the >>> operator
    // performs arithmetic (sign-extending) shift instead of logical shift.
    // ========================================================================
    always @(*) begin
        case (i_alu_ctrl)
            // --- Logic Operations ---
            4'b0000: o_result = i_a & i_b;             // AND: Bitwise AND (AND, ANDI)
            4'b0001: o_result = i_a | i_b;             // OR:  Bitwise OR  (OR, ORI)
            4'b0100: o_result = i_a ^ i_b;             // XOR: Bitwise XOR (XOR, XORI)

            // --- Arithmetic Operations ---
            4'b0010: o_result = i_a + i_b;             // ADD: Addition (ADD, ADDI, Load/Store addr, AUIPC, JAL/JALR)
            4'b0110: o_result = i_a - i_b;             // SUB: Subtraction (SUB, BEQ/BNE comparison)

            // --- Shift Operations (shamt = i_b[4:0], 5 bits per RV32I spec) ---
            4'b0101: o_result = i_a >> i_b[4:0];       // SRL: Shift Right Logical  (SRL, SRLI)  - fills with 0s
            4'b0111: o_result = i_a << i_b[4:0];       // SLL: Shift Left Logical   (SLL, SLLI)  - fills with 0s
            4'b1000: o_result = $signed(i_a) >>> i_b[4:0]; // SRA: Shift Right Arithmetic (SRA, SRAI) - preserves sign bit

            // --- Comparison Operations (result is 1 or 0) ---
            4'b1001: o_result = ($signed(i_a) < $signed(i_b))   // SLT:  Set Less Than Signed   (SLT, SLTI)
                                ? {{WIDTH-1{1'b0}}, 1'b1}       //       Result = 1 if a < b (signed)
                                : {WIDTH{1'b0}};                //       Result = 0 otherwise

            4'b1010: o_result = (i_a < i_b)                     // SLTU: Set Less Than Unsigned  (SLTU, SLTIU)
                                ? {{WIDTH-1{1'b0}}, 1'b1}       //       Result = 1 if a < b (unsigned)
                                : {WIDTH{1'b0}};                //       Result = 0 otherwise

            // --- Default: prevents latch inference ---
            default: o_result = {WIDTH{1'b0}};          // Undefined control codes output zero
        endcase
    end

endmodule
