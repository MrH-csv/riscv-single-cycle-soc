module adder_4_32b #(
	parameter WIDTH = 32
)(
	input  [WIDTH-1:0] i_a,
	input  [WIDTH-1:0] i_b,
	output [WIDTH-1:0] o_sum
);

	assign o_sum = i_a + i_b;

endmodule
