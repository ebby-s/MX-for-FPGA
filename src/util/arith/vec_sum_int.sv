module vec_sum_int #(
    parameter bit_width  = 16,
    parameter length     = 32,
    parameter sum_width  = bit_width + $clog2(length),
    parameter tree_depth = $clog2(length)
)(
    input  logic signed [bit_width-1:0] i_vec [length],
    output logic signed [sum_width-1:0] o_sum
);

    // Define adder tree.
    for(genvar i=0; i<tree_depth; i++) begin : tree_add
        // Declare adders.
        logic signed [bit_width+i-1:0] p0_add0 [length>>(1+i)];
        logic signed [bit_width+i-1:0] p0_add1 [length>>(1+i)];
        logic signed   [bit_width+i:0] p0_sum  [length>>(1+i)];

        for(genvar j=0; j<length>>(1+i); j++) begin
            assign p0_sum[j] = p0_add0[j] + p0_add1[j];
        end

        // Connections to previous layers.
        if(i != 0) begin
            for(genvar j=0; j<(length>>(1+i)); j++) begin
                assign p0_add0[j] = tree_add[i-1].p0_sum[2*j];
                assign p0_add1[j] = tree_add[i-1].p0_sum[2*j+1];
            end
        end else begin
            for(genvar j=0; j<(length>>(1+i)); j++) begin
                assign p0_add0[j] = i_vec[2*j];
                assign p0_add1[j] = i_vec[2*j+1];
            end
        end
    end

    // Assign outputs.
    assign o_sum = tree_add[tree_depth-1].p0_sum[0];

endmodule
