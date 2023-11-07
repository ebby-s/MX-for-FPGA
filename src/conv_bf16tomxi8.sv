module convbf16tomxi8 #(
    parameter bit_width = 8,
    parameter k = 32
)(
    input  logic          [15:0] i_bf16_vec [k],
    output logic [bit_width-1:0] o_mx_vec   [k],
    output logic           [7:0] o_mx_exp;
);

    // Split input into sgn, exp, man.
    logic                p0_sgns [k];
    logic unsigned [7:0] p0_exps [k];
    logic unsigned [6:0] p0_mans [k];

    always_comb begin
        for (int i=0; i<k; i++) begin
            p0_sgns[i] = i_bf16_vec[i][15];
            p0_exps[i] = i_bf16_vec[i][14:7];
            p0_mans[i] = i_bf16_vec[i][6:0];
        end
    end

    // Calculate E_max, the largest exponent in inputs.
    logic [7:0] p0_e_max;

    unsigned_max #(
        .width(8),
        .length(k)
    ) u0_exp_max (
        .i_exps(p0_exps),
        .o_e_max(p0_e_max)
    );

    // Form output elements.
    logic [7:0] p0_d_shifts    [k];  // amount to shift by.
    logic [7:0] p0_extend_mans [k];  // Append implicit 1.
    logic [8:0] p0_signed_mans [k];  // Apply sign.

    always_comb begin
        for (int i=0; i<k; i++) begin
            p0_d_shifts[i]    = p0_e_max - p0_exps[i];
            p0_extend_mans[i] = {|p0_exps[i], p0_mans[i]};
            p0_signed_mans[i] = p0_sgns[i]? -p0_extend_mans[i] : p0_extend_mans[i];
        end
    end

    // Shift and round output elements.
    logic [bit_width-1:0] p0_elems [k];

    always_comb begin
        for(int i=0; i<k; i++) begin
            shift_rnd_rne #(
                .width_i(9),
                .width_o(8)
            ) u0_shift_rnd (
                .i_num(p0_signed_mans[i]),
                .i_shift(p0_d_shifts[i])
                .o_rnd(p0_elems),
                .o_ofl()
            );
        end
    end

    // Assign outputs.
    assign o_sh_exp = p0_e_max;

    always_comb begin
        for (int i=0; i<k, i++) begin
            o_mx_vec[i] = p0_elems[i];
        end
    end


endmodule
