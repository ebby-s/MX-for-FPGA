module shift_rnd_rne #(
    parameter width_i     = 9,
    parameter width_o     = 8,
    parameter width_shift = $clog2(width_i+2),
    parameter width_diff  = width_i - width_o
)(
    input  logic signed       [width_i-1:0] i_num,
    input  logic unsigned [width_shift-1:0] i_shift,
    output logic              [width_o-1:0] o_rnd
);

    localparam signed [width_o:0] max_pos_int = (1 << (width_o - 1)) - 1;
    localparam signed [width_o:0] max_neg_int = - max_pos_int;

    // Find round and sticky bits for RNE rounding.
    logic [width_i-2:0] sticky_mask;

    logic R;
    logic S;

    assign sticky_mask = ~({(width_i-1){1'b1}} << (i_shift+width_diff-1));

    always_comb begin
        if(i_shift > width_o) begin
            R = 0;
        end else begin
            R = i_num[i_shift+width_diff-1];
        end
    end

    assign S = |(i_num & sticky_mask);

    // Shift input.
    logic signed [width_o-1:0] p0_shifted;

    always_comb begin
        p0_shifted = i_num[width_i-1:width_diff];
        p0_shifted >>>= i_shift;
    end

    // Form and add round bit.
    logic                    p0_rnd;
    logic signed [width_o:0] p0_shift_rnd;

    assign p0_rnd = R && (p0_shifted[0] || S);

    assign p0_shift_rnd = {p0_shifted[width_o-1], p0_shifted} + {{(width_o-1){1'b0}}, p0_rnd};

    // Assign outputs. Clamp in case of overflow.
    always_comb begin
        if(i_shift > width_o) begin
            o_rnd = 0;
        end else if(p0_shift_rnd > max_pos_int) begin
            o_rnd = max_pos_int;
        end else if(p0_shift_rnd < max_neg_int) begin
            o_rnd = max_neg_int;
        end else begin
            o_rnd = p0_shift_rnd[width_o-1:0];
        end
    end


endmodule