module vec_mul_i8 #(
    parameter bit_width = 8,
    parameter length    = 32,
    parameter prd_width = 2*bit_width
)(
    input  logic [bit_width-1:0] i_vec_a [length],
    input  logic [bit_width-1:0] i_vec_b [length],
    output logic [prd_width-1:0] o_prd   [length]
);

    // Elementwise multiplication of vectors.
    logic [prd_width-1:0] p0_prd [length];

    always_comb begin
        for(int i=0; i<length; i++) begin
            p0_prd[i] = i_vec_a[i] * i_vec_b[i];
        end
    end

    // Assign outputs.
    always_comb begin
        for(int i=0; i<length; i++) begin
           o_prd[i] = p0_prd[i];
        end
    end

endmodule
