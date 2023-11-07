module shift_rnd_rne #(
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

    // Find round and sticky bits for RNE rounding.
    logic R;
    logic S;

    always_comb begin
        if((i_shift+width_diff) == 1) begin
            assign R = i_num[0];
            assign S = 0;

        end else if((i_shift+width_diff-1) <= (width_i-1)) begin
            assign R =  i_num[i_shift+width_diff-1];
            assign S = |i_num[i_shift+width_diff-2:0];

        end else begin
            assign R = 0;
            assign S = 0;
        end
    end

    // Shift input.
    logic signed [width_o-1:0] p0_shifted;

    assign p0_shifted = i_num >> (i_shift+width_diff);

    // Form and add round bit.
    logic                    p0_rnd;
    logic signed [width_o:0] p0_shift_rnd;
    logic                    p0_ofl;

    assign p0_rnd = R && (p0_shifted[0] || S);

    assign p0_shift_rnd = p0_shifted + {{(width_o-1){1'b0}}, p0_rnd};

    assign p0_ofl = p0_shift_rnd[width_o] ^ p0_shift_rnd[width_o-1];

    // Assign outputs.
    assign o_ofl = p0_ofl;

    // Clamp in case of overflow.
    if(p0_ofl && p0_shift_rnd[width_o]) begin
        assign o_rnd = {1'b1, {(width_o-1){1'b0}}};     // Max neg. integer.
    end else if(p0_ofl && ~p0_shift_rnd[width_o]) begin
        assign o_rnd = {1'b0, {(width_o-1){1'b1}}};     // Max pos. integer.
    end else begin
        assign o_rnd = p0_shift_rnd[width_o-1:0];
    end


endmodule