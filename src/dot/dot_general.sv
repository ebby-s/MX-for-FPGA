module dot_general #(
    parameter C = 256,

    parameter k = 32,
    parameter bit_width = 8,
    parameter out_width = 8
)(
    input  logic i_clk,

    input  logic signed [bit_width-1:0] i_X     [C],
    input  logic signed [bit_width-1:0] i_Y     [C],
    input  logic         [8-1:0] i_S     [C/k],
    input  logic         [8-1:0] i_T     [C/k],
    output logic [out_width-1:0] o_dp,
    output logic         [8-1:0] o_scale
);

    localparam dp_width = 2*bit_width + $clog2(k);

    localparam length = C/k;
    localparam tree_depth = $clog2(length);

    // Sum within blocks
    logic signed [dp_width-1:0] dot_out [C/k];

    for(genvar i=0; i<(C/k); i++) begin
        dot_int #(
            .bit_width(bit_width),
            .k(k)
        ) u_dot_int (
            .i_vec_a(i_X[i*k +: k]),
            .i_vec_b(i_Y[i*k +: k]),
            .o_dp(dot_out[i])
        );
    end

    // Sum scales
    logic [8-1:0] dot_scales [C/k];

    for(genvar i=0; i<(C/k); i++) begin
        assign dot_scales[i] = i_S[i] + i_T[i];
    end

    // Sum across blocks
    for(genvar i=0; i<tree_depth; i++) begin : tree_add
        // Declare adders.
        logic signed [dp_width-1:0] p0_add0   [length>>(1+i)];
        logic signed [dp_width-1:0] p0_add1   [length>>(1+i)];
        logic signed [dp_width-1:0] p0_sum    [length>>(1+i)];
        logic signed        [8-1:0] p0_scale0 [length>>(1+i)];
        logic signed        [8-1:0] p0_scale1 [length>>(1+i)];
        logic signed        [8-1:0] p0_scale  [length>>(1+i)];

        for(genvar j=0; j<length>>(1+i); j++) begin
            add_nrm #(
                .int_w(dp_width)
            ) u_add_nrm (
                .i_op0(p0_add0[j]),
                .i_op1(p0_add1[j]),
                .i_scale0(p0_scale0[j]),
                .i_scale1(p0_scale1[j]),
                .out(p0_sum[j]),
                .o_scale(p0_scale[j])
            );
        end

        // Connections to previous layers.
        if(i != 0) begin
            for(genvar j=0; j<(length>>(1+i)); j++) begin
                assign p0_add0[j] = tree_add[i-1].p0_sum[2*j];
                assign p0_add1[j] = tree_add[i-1].p0_sum[2*j+1];
                assign p0_scale0[j] = tree_add[i-1].p0_scale[2*j];
                assign p0_scale1[j] = tree_add[i-1].p0_scale[2*j+1];
            end
        end else begin
            for(genvar j=0; j<(length>>(1+i)); j++) begin
                assign p0_add0[j] = dot_out[2*j];
                assign p0_add1[j] = dot_out[2*j+1];
                assign p0_scale0[j] = dot_scales[2*j];
                assign p0_scale1[j] = dot_scales[2*j+1];
            end
        end
    end


    // Form output
    assign o_dp = tree_add[tree_depth-1].p0_sum[0];
    assign o_scale = tree_add[tree_depth-1].p0_scale[0];


endmodule
