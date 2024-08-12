module add_nrm #(
    parameter int_w = 24,
    parameter scale_w = 8
)(
    input  logic   [int_w-1:0] i_op0,
    input  logic   [int_w-1:0] i_op1,
    input  logic unsigned [scale_w-1:0] i_scale0,
    input  logic unsigned [scale_w-1:0] i_scale1,

    output logic   [int_w-1:0] out,
    output logic [scale_w-1:0] o_scale
);



// Sort operands.
logic signed   [int_w-1:0] op_lrg;
logic signed   [int_w-1:0] op_sml;
logic [scale_w-1:0] scale_lrg;
logic [scale_w-1:0] scale_sml;

always_comb begin
    if(i_scale0 < i_scale1) begin
        op_lrg = i_op1;
        op_sml = i_op0;
        scale_lrg = i_scale1;
        scale_sml = i_scale0;

    end else begin
        op_lrg = i_op0;
        op_sml = i_op1;
        scale_lrg = i_scale0;
        scale_sml = i_scale1;
    end
end


// Calculate exponent difference.
logic [scale_w-1:0] scale_diff;

assign scale_diff = scale_lrg - scale_sml;


// Calculate sticky bit.
logic [int_w-1:0] sticky_mask;
logic S_bit;

assign sticky_mask = ~({int_w{1'b1}} << (scale_diff-3));

always_comb begin
    if(scale_diff > 3) begin
        S_bit = |(op_sml & sticky_mask);
    end else begin
        S_bit = 0;
    end
end


// Shift smaller operand.
logic [int_w-1+3:0] op_sml_shift;

always_comb begin
    op_sml_shift = ({op_sml, 3'h0} >> scale_diff);
    op_sml_shift[0] &= S_bit;
end


// Add operands.
logic [int_w+3:0] sum;

assign sum = {op_lrg[int_w-1], op_lrg, 3'h0} + {op_sml_shift[int_w-1+3], op_sml_shift};


// Count leading digit and normalise sum.
logic [int_w+3:0] sum_clz_prep;
logic [$clog2(int_w+1+3+1)-1:0] sum_clz;
logic [int_w+3:0] aligned_sum;

assign sum_clz_prep = sum[int_w+3] ? ~sum : sum;

clz_int #(
    .width_i(int_w+1+3)
) u_clz (
    .i_num(sum_clz_prep),
    .o_lz(sum_clz)
);

assign aligned_sum = sum << (sum_clz-1);


// Round normalised output.
logic [int_w:0] sum_rnd;

assign sum_rnd = aligned_sum[int_w+3:4] + (aligned_sum[3] && (|aligned_sum[2:0] || aligned_sum[4]));

// Adjust scale.
logic [7:0] scale_adj;

assign scale_adj = scale_lrg + sum_clz - 1;


// Assign output.
always_comb begin
    if (sum_rnd[int_w] ^ sum_rnd[int_w-1]) begin
        out = sum_rnd[int_w:1];
        o_scale = scale_adj + 1;
    end else begin
        out = sum_rnd[int_w-1:0];
        o_scale = scale_adj;
    end
end


endmodule
