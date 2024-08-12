module dot_fp_spec #(
    parameter exp_width = 5,
    parameter man_width = 2,
    parameter k         = 32,
    parameter e4m3_spec = (exp_width == 4) && (man_width == 3),
    parameter bit_width = 1 + exp_width + man_width,
    parameter fi_width  = man_width + 2,
    parameter prd_width = 2 * ((1<<exp_width) + man_width),
    parameter out_width = prd_width + $clog2(k)
)(
    input  logic signed [bit_width-1:0] i_vec_a [k],
    input  logic signed [bit_width-1:0] i_vec_b [k],
    output logic signed [out_width-1:0] o_dp,
    output logic                        o_nan
);

    // Parameters and functions.
    function logic is_special(input logic [bit_width-2:0] i_fp8_num);

        if(e4m3_spec) begin
            return &i_fp8_num[bit_width-2:0];
        end else begin
            return &i_fp8_num[bit_width-2:man_width];
        end

    endfunction


    // Check for specials.
    logic [k-1:0] p0_nan_a;
    logic [k-1:0] p0_nan_b;
    logic p0_nan;

    always_comb begin
        for(int i=0; i<k; i++) begin
            p0_nan_a[i] = is_special(i_vec_a[i]);
            p0_nan_b[i] = is_special(i_vec_b[i]);
        end
    end

    assign p0_nan = |p0_nan_a || |p0_nan_b;

    // Calculate dot product assuming no specials.
    logic signed [out_width-1:0] p0_sum;

    dot_fp #(
        .exp_width(exp_width),
        .man_width(man_width),
        .k(k)
    ) u_dot_fp6 (
        .i_vec_a(i_vec_a),
        .i_vec_b(i_vec_b),
        .o_dp(p0_sum)
    );

    // Assign output.
    assign o_dp = p0_sum;

    assign o_nan = p0_nan;
        

endmodule
