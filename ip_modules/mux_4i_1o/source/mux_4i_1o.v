/******************************************************************************
 * Module:      mux_4i_1o
 * Description: 4-to-1 Multiplexer — Generic, parameterized, purely
 *              combinational building block for RISC-V datapath.
 *
 * Parameters:
 *   WIDTH  — Bit-width of data buses (default 32).
 *
 * Ports:
 *   i_d0   [WIDTH-1:0]  — Data input 0 (selected when i_sel == 2'b00)
 *   i_d1   [WIDTH-1:0]  — Data input 1 (selected when i_sel == 2'b01)
 *   i_d2   [WIDTH-1:0]  — Data input 2 (selected when i_sel == 2'b10)
 *   i_d3   [WIDTH-1:0]  — Data input 3 (selected when i_sel == 2'b11)
 *   i_sel  [1:0]        — Select lines
 *   o_out  [WIDTH-1:0]  — Multiplexer output
 *
 * Notes:
 *   - A default case drives o_out to 0 to prevent latch inference.
 *   - Intended for synthesis on Intel Quartus Prime.
 *****************************************************************************/

module mux_4i_1o
#(
    parameter WIDTH = 32
)
(
    input  wire [WIDTH-1:0] i_d0,
    input  wire [WIDTH-1:0] i_d1,
    input  wire [WIDTH-1:0] i_d2,
    input  wire [WIDTH-1:0] i_d3,
    input  wire [1:0]       i_sel,
    output reg  [WIDTH-1:0] o_out
);

    // Combinational mux logic — no latches inferred
    always @(*) begin
        case (i_sel)
            2'b00:   o_out = i_d0;
            2'b01:   o_out = i_d1;
            2'b10:   o_out = i_d2;
            2'b11:   o_out = i_d3;
            default: o_out = {WIDTH{1'b0}};
        endcase
    end

endmodule
