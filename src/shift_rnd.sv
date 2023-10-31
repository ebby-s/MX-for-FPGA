module shift_rnd #(
    parameter width_i     = 9,
    parameter width_o     = 8,
    parameter width_shift = $clog2(width_i+2),
    parameter width_diff  = width_i - width_o
)(
    input  logic signed       [width_i-1:0] i_num,
    input  logic unsigned [width_shift-1:0] i_shift,
    output logic              [width_o-1:0] o_rnd,
    output logic                            o_ofl
);


    logic G;
    logic R;
    logic S;

    always_comb begin
        if((width_diff+i_shift) == 1) begin
            assign G = i_num[0];
            assign R = 0
            assign S = 0

        end else if((width_diff+i_shift) == 2) begin
            assign G = i_num[1];
            assign R = i_num[0];
            assign S = 0;

        end else if(i_shift+width_diff-1 <= width_i-1) begin
            assign G =  i_num[i_shift+width_diff-1];
            assign R =  i_num[i_shift+width_diff-2];
            assign S = |i_num[i_shift+width_diff-3:0];

        end else begin
            assign G = 0;
            assign R = 0;
            assign S = 0;
        end
    end

    logic [width_o-1:0] p0_shifted;

    assign p0_shifted = i_num >> (i_shift+width_diff);


endmodule