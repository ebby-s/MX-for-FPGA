module unsigned_max #(
    parameter width   = 8,   // Width of inputs.
    parameter length  = 32,  // Number of values being compared.
    parameter pl_freq = 1,   // Pipeline frequency within tree.
    parameter flop_output = 1
)(
    input  logic i_clk,

    input  logic unsigned [width-1:0] i_exps [length],
    output logic unsigned [width-1:0] o_e_max
);

    // Depth of tree, length of longest path.
    localparam tree_depth = $clog2(length);

    // Find largest value using a tree.
    logic unsigned [width-1:0] p0_e_max;

    for(genvar i=0; i<tree_depth; i++) begin : tree_max
        // Declare operands and outputs to max().
        logic [width-1:0] p0_op0 [length>>(1+i)];
        logic [width-1:0] p0_op1 [length>>(1+i)];
        logic [width-1:0] p0_max [length>>(1+i)];

        for(genvar j=0; j<length>>(1+i); j++) begin
            assign p0_max[j] = (p0_op0[j] > p0_op1[j]) ? p0_op0[j] : p0_op1[j];
        end

        // Connections to previous layers.
        for(genvar j=0; j<(length>>(1+i)); j++) begin

            if(i != 0) begin
                if(i%pl_freq == 0) begin
                    always_ff @(posedge i_clk) begin
                        p0_op0[j] <= tree_max[i-1].p0_max[2*j];
                        p0_op1[j] <= tree_max[i-1].p0_max[2*j+1];
                    end
                end else begin
                    assign p0_op0[j] = tree_max[i-1].p0_max[2*j];
                    assign p0_op1[j] = tree_max[i-1].p0_max[2*j+1];
                end

            end else begin
                assign p0_op0[j] = i_exps[2*j];
                assign p0_op1[j] = i_exps[2*j+1];
            end
        end
    end

    assign p0_e_max = tree_max[tree_depth-1].p0_max[0];

    // Assign outputs.
    if(flop_output) begin
        always_ff @(posedge i_clk) begin
            o_e_max <= p0_e_max;
        end
    end else begin
        assign o_e_max = p0_e_max;
    end

endmodule
