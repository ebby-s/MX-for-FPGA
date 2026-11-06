module add_nrm #(
    parameter int_w = 24,
    parameter scale_w = 8,
    parameter implicit_man = 1   // When 1, operands are FP mantissas (sign + fraction, implicit 1). When 0, two's complement integers.
)(
    input  logic   [int_w-1:0] i_op0,
    input  logic   [int_w-1:0] i_op1,
    input  logic unsigned [scale_w-1:0] i_scale0,
    input  logic unsigned [scale_w-1:0] i_scale1,

    output logic   [int_w-1:0] out,
    output logic [scale_w-1:0] o_scale
);



// Sign-extend operands.
logic signed [int_w:0] op0_sxt;
logic signed [int_w:0] op1_sxt;

assign op0_sxt = {i_op0[int_w-1], i_op0};
assign op1_sxt = {i_op1[int_w-1], i_op1};

// Form significands. Mantissa operands append the implicit leading 1 (zero exponents are subnormal);
// integer operands use their magnitude.
logic [int_w:0] mag0;
logic [int_w:0] mag1;

always_comb begin
    if(implicit_man) begin
        mag0 = |i_scale0 ? {1'b1, i_op0[int_w-2:0]} : {i_op0[int_w-2:0], 1'b0};
        mag1 = |i_scale1 ? {1'b1, i_op1[int_w-2:0]} : {i_op1[int_w-2:0], 1'b0};
    end else begin
        mag0 = op0_sxt[int_w] ? -op0_sxt : op0_sxt;
        mag1 = op1_sxt[int_w] ? -op1_sxt : op1_sxt;
    end
end

// Apply signs.
logic signed [int_w:0] op0_ext;
logic signed [int_w:0] op1_ext;

assign op0_ext = i_op0[int_w-1] ? -mag0 : mag0;
assign op1_ext = i_op1[int_w-1] ? -mag1 : mag1;


// Sort operands.
logic signed   [int_w:0] op_lrg;
logic signed   [int_w:0] op_sml;
logic [scale_w-1:0] scale_lrg;
logic [scale_w-1:0] scale_sml;

always_comb begin
    if(i_scale0 < i_scale1) begin
        op_lrg = op1_ext;
        op_sml = op0_ext;
        scale_lrg = i_scale1;
        scale_sml = i_scale0;

    end else begin
        op_lrg = op0_ext;
        op_sml = op1_ext;
        scale_lrg = i_scale0;
        scale_sml = i_scale1;
    end
end


// Calculate exponent difference.
logic [scale_w-1:0] scale_diff;

assign scale_diff = scale_lrg - scale_sml;


// Calculate sticky bit.
logic [int_w:0] sticky_mask;
logic [int_w:0] op_sml_mag;
logic S_bit;

assign sticky_mask = ~({(int_w+1){1'b1}} << (scale_diff-3));
assign op_sml_mag = op_sml[int_w] ? -op_sml : op_sml;

always_comb begin
    if(scale_diff > 3) begin
        S_bit = |(op_sml_mag & sticky_mask);
    end else begin
        S_bit = 0;
    end
end


// Shift smaller operand.
logic signed [int_w+3:0] op_sml_shift;

always_comb begin
    op_sml_shift = ($signed({op_sml, 3'h0}) >>> scale_diff);
end


// Add operands.
logic signed [int_w+4:0] sum;

assign sum = {op_lrg[int_w], op_lrg, 3'h0} + {op_sml_shift[int_w+3], op_sml_shift};


// Magnitude of the sum.
logic [int_w+4:0] mag_sum;

assign mag_sum = sum[int_w+4] ? -sum : sum;


// Count leading digit and normalise sum.
logic [int_w+4:0] sum_clz_prep;
logic [$clog2(int_w+2+3+1)-1:0] sum_clz;
logic [int_w+4:0] aligned_sum;

assign sum_clz_prep = mag_sum;

clz_int #(
    .width_i(int_w+2+3)
) u_clz (
    .i_num(sum_clz_prep),
    .o_lz(sum_clz)
);

assign aligned_sum = sum_clz_prep << (sum_clz-1);


// Round normalised output. S_bit covers remainder bits lost by the floor shift of the smaller
// operand (true sum = fixed point + S_bit content). For a positive fixed-point sum this is extra
// remainder (may round up); for a negative one the fixed point overstates the magnitude, so only
// window bits above half an LSB may round up.
logic sum_adds;
logic [int_w:0] sum_rnd;

assign sum_adds = ~sum[int_w+4];
assign sum_rnd = aligned_sum[int_w+3:4] + (aligned_sum[3] && ( (S_bit && !sum_adds) ? (aligned_sum[2] || aligned_sum[1])
                                                          : (|aligned_sum[2:0] || aligned_sum[4] || S_bit) ));

// Adjust scale. The sum is shifted left by sum_clz-1, so the scale decreases by the same amount.
logic [7:0] scale_adj;

assign scale_adj = scale_lrg - sum_clz + 2;


// Assign output.
logic sum_sgn;

assign sum_sgn = sum[int_w+4];

always_comb begin
    if(sum == 0) begin                       // Exact zero.
        out = '0;
        o_scale = '0;
    end else if(sum_rnd[int_w]) begin        // Rounding overflow: renormalise.
        out = {sum_sgn, sum_rnd[int_w-1:1]};
        o_scale = scale_adj + 1;
    end else begin
        out = {sum_sgn, sum_rnd[int_w-2:0]};
        o_scale = scale_adj;
    end
end


endmodule
