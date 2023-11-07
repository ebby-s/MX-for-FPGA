module dot_i8 #(
    parameter bit_width = 8,
    parameter k         = 32,
    parameter prd_width = 2*bit_width,
    parameter out_width = prd_width + $clog2(k)
)(
    input  logic [bit_width-1:0] i_vec_a [k],
    input  logic [bit_width-1:0] i_vec_b [k],
    output logic [out_width-1:0] o_dp
);

    // Perform multiplications.
    logic [prd_width-1:0] p0_prd [k];

    vec_mul_i8 #(
        .bit_width(bit_width),
        .length(k)
    ) u_vec_mul (
        .i_vec_a(i_vec_a),
        .i_vec_b(i_vec_b),
        .o_prd(p0_prd)
    );

    // Calculate sum.
    logic [out_width-1:0] p0_sum;

    vec_sum_i8 #(
        .bit_width(prd_width),
        .length(k)
    ) u_tree_add (
        .i_vec(p0_prd),
        .o_sum(p0_sum)
    );

    assign o_dp = o_sum;


endmodule
