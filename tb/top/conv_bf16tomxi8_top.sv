module conv_top #(
    parameter bit_width = 8
)(
    input  logic i_clk,

    input  logic          [15:0] i_bf16_vec [32],
    output logic [bit_width-1:0] o_mx_vec   [32],
    output logic           [7:0] o_mx_exp
);

    logic [15:0] p1_bf16_vec [32];

    always_ff @(posedge i_clk) begin
        for (int i=0; i<32; i++) begin
            p1_bf16_vec[i] <= i_bf16_vec[i];
        end
    end


    conv_bf16tomxi8 u_conv(
        .i_clk(i_clk),
        .i_bf16_vec(p1_bf16_vec),
        .o_mx_vec(o_mx_vec),
        .o_mx_exp(o_mx_exp)
    );


endmodule
