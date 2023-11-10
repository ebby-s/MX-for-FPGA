module unsigned_max_tb #(
    parameter width  = 8,
    parameter length = 32
)(
    input logic i_clk,
    input logic i_rst_n,
    input logic unsigned [width-1:0] i_exps [length]
);

    localparam max_tree_depth = $clog2(length);

    // DUT
    logic [width-1:0] p1_e_max        [max_tree_depth+3];
    logic [width-1:0] p1_e_max_o_flop [max_tree_depth+3];

    for(genvar i=1; i<max_tree_depth+3; i++) begin : dut_delay

        unsigned_max #(
            .width(width),
            .length(length),
            .pl_freq(i),
            .flop_output(0)
        ) u0_exp_max (
            .i_clk(i_clk),
            .i_exps(i_exps),
            .o_e_max(p1_e_max[i])
        );

        unsigned_max #(
            .width(width),
            .length(length),
            .pl_freq(i),
            .flop_output(1)
        ) u1_exp_max (
            .i_clk(i_clk),
            .i_exps(i_exps),
            .o_e_max(p1_e_max_o_flop[i])
        );
    end


    // Reference
    logic unsigned [width-1:0] p0_ref_e_max;

    always_comb begin
        p0_ref_e_max = 0;
        for(int i=0; i<length; i++) begin
            p0_ref_e_max = p0_ref_e_max > i_exps[i] ? p0_ref_e_max : i_exps[i];
        end
    end

    // Delay reference
    logic [width-1:0] dly_ref_e_max [max_tree_depth+2];

    assign dly_ref_e_max[0] = p0_ref_e_max;

    always_ff @(posedge i_clk) begin
        for(int i=1; i<max_tree_depth+2; i++) begin
            dly_ref_e_max[i] <= dly_ref_e_max[i-1];
        end
    end


    // Assert properties
    default clocking @(posedge i_clk); endclocking
    default disable iff (!i_rst_n);

    for(genvar i=1; i<max_tree_depth+3; i++) begin : ast_delay

        if(max_tree_depth/i > 0) begin
            ast_u_max: assert property(
                i_rst_n ##((max_tree_depth-1)/i) (p1_e_max[i] == dly_ref_e_max[(max_tree_depth-1)/i])
            );

            ast_u_max_o_flop: assert property(
                i_rst_n ##((max_tree_depth-1)/i+1) (p1_e_max_o_flop[i] == dly_ref_e_max[((max_tree_depth-1)/i)+1])
            );

        end else begin
            ast_u_max: assert property(
                p1_e_max[i] == dly_ref_e_max[0]
            );

            ast_u_max_o_flop: assert property(
                i_rst_n ##1 p1_e_max_o_flop[i] == dly_ref_e_max[1]
            );
        end
    end

endmodule
