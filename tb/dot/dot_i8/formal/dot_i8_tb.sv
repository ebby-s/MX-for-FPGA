module dot_i8_tb #(
    parameter bit_width  = 8,
    parameter k = 4,
    parameter out_width = 2*bit_width + $clog2(k)
)(
    input logic i_clk,
    input logic i_rst_n,
    input logic signed [bit_width-1:0] i_op0 [k],
    input logic signed [bit_width-1:0] i_op1 [k]
);


    // DUT
    logic [out_width-1:0] p0_dp_out;

    dot_i8 #(
        .bit_width(bit_width),
        .k(k)
    ) u0_dot_i8 (
        .i_vec_a(i_op0),
        .i_vec_b(i_op1),
        .o_dp(p0_dp_out)
    );


    // Reference
    logic signed [out_width-1:0] ref_dp_out;

    always_comb begin
        ref_dp_out = 0;
        for(int i=0; i<k; i++) begin
            ref_dp_out += $signed(i_op0[i]) * $signed(i_op1[i]);
        end
    end


    // Assert properties
    default clocking @(posedge i_clk); endclocking
    default disable iff (!i_rst_n);

    ast_dp_out: assert property(
        p0_dp_out == ref_dp_out
    );

endmodule
