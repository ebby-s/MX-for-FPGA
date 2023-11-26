module mul_i8 #(
    parameter bit_width = 8,
    parameter prd_width = 2*bit_width
)(
    input  logic signed [bit_width-1:0] i_op0,
    input  logic signed [bit_width-1:0] i_op1,
    output logic signed [prd_width-1:0] o_prd
);


    logic unsigned [bit_width-1:0] u_op0;
    logic unsigned [bit_width-1:0] u_op1;
    logic unsigned [prd_width-1:0] u_prd;
    logic prd_sign;

    always_comb begin
        prd_sign = ((i_op0 < 0) ^ (i_op1 < 0));

        u_op0 = (i_op0 < 0) ? -i_op0 : i_op0;
        u_op1 = (i_op1 < 0) ? -i_op1 : i_op1;

        u_prd = u_op0 * u_op1;

        o_prd = prd_sign ? -u_prd : u_prd;
    end


endmodule
