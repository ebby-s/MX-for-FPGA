module vec_mul_int #(
    parameter bit_width = 8,
    parameter length    = 32,
    parameter prd_width = 2*bit_width
)(
    input  logic signed [bit_width-1:0] i_vec_a [length],
    input  logic signed [bit_width-1:0] i_vec_b [length],
    output logic signed [prd_width-1:0] o_prd   [length]
);

    // Elementwise multiplication of vectors.
    logic signed [prd_width-1:0] p0_prd [length];

    for(genvar i=0; i<length; i++) begin : mul_loop

        mul_int #(
            .bit_width(bit_width)
        ) u_mul (
            .i_op0(i_vec_a[i]),
            .i_op1(i_vec_b[i]),
            .o_prd(p0_prd[i])
        );

    end

    // Assign outputs.
    always_comb begin
        for(int i=0; i<length; i++) begin
           o_prd[i] = p0_prd[i];
        end
    end

endmodule
