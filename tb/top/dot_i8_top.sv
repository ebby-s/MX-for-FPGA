module dot_int_top #(
    parameter bit_width  = 8,
    parameter k = 32,
    parameter out_width = 2*bit_width + $clog2(k)
)(
    input  logic i_clk,

    input  logic signed [bit_width-1:0] i_op0 [k],
    input  logic signed [bit_width-1:0] i_op1 [k],
    output logic signed [out_width-1:0] o_dp
);

    logic signed [bit_width-1:0] p1_op0 [k];
    logic signed [bit_width-1:0] p1_op1 [k];

    always_ff @(posedge i_clk) begin
        for (int i=0; i<k; i++) begin
            p1_op0[i] <= i_op0[i];
            p1_op1[i] <= i_op1[i];
        end
    end


    logic signed [out_width-1:0] p1_dp;

    dot_int #(
        .bit_width(bit_width),
        .k(k)
    ) u0_dot_int (
        .i_vec_a(p1_op0),
        .i_vec_b(p1_op1),
        .o_dp(p1_dp)
    );

    always_ff @(posedge i_clk) begin
        o_dp <= p1_dp;
    end

endmodule
