module fp_rnd_rne #(
    parameter width_i     = 8,
    parameter width_o_exp = 3,
    parameter width_o_man = 2,
    parameter width_shift = 8
)(
    input  logic signed       [width_i-1:0] i_num,
    input  logic unsigned [width_shift-1:0] i_shift,
    output logic          [width_o_exp-1:0] o_exp,
    output logic          [width_o_man-1:0] o_man
);

    // Max exponent/mantissa values of element type.
    localparam max_exp_elem = (1 << width_o_exp) - 1;
    localparam max_man_elem = (1 << width_o_man) - 1;

    // Count leading zeros, align input.
    logic [$clog2(width_i):0] lz_num;
    logic [width_i-1:0] aligned_num;

    clz_i8 #(
        .width_i(width_i)
    ) u_clz (
        .i_num(i_num),
        .o_lz(lz_num)
    );

    assign aligned_num = i_num << lz_num;

    // Handle non-denormal case. Round mantissa.
    logic R_nrm;
    logic S_nrm;
    logic p0_nrm_rnd;

    assign R_nrm =  aligned_num[width_i-width_o_man-2];
    assign S_nrm = |aligned_num[width_i-width_o_man-3:0];
    assign p0_nrm_rnd = R_nrm && (aligned_num[width_i-width_o_man-1] || S_nrm);

    logic   [width_o_man:0] p0_man_nrm_ofl;  // Extra bit to check for overflow after rounding.
    logic [width_o_man-1:0] p0_man_nrm;      // Output mantissa if output is not denormal.
    logic                   p0_exp_nrm_ofl;  // 1 if mantissa overflowed, 0 otherwise.

    assign p0_man_nrm_ofl = aligned_num[width_i-2:width_i-width_o_man-1] + {{(width_o_man-1){1'b0}}, p0_nrm_rnd};

    assign p0_exp_nrm_ofl = p0_man_nrm_ofl[width_o_man];
    assign p0_man_nrm     = p0_man_nrm_ofl[width_o_man-1:0];

    // Truncation necessary if exponent overflows.
    logic p0_truncate;

    assign p0_truncate = p0_exp_nrm_ofl && (i_shift == 0) && (lz_num == 0);

    // Handle denormal case. Round mantissa.
    logic [width_shift+1:0] p0_dnm_shift; // Amount to shift by if output is denormal.
    logic [width_i-2:0] sticky_mask;

    logic R_dnm;
    logic S_dnm;
    logic p0_dnm_rnd;

    assign p0_dnm_shift = $unsigned(i_shift) + $unsigned(lz_num) + $unsigned(width_i) - $unsigned(max_exp_elem) - $unsigned(width_o_man);

    assign sticky_mask = ~({(width_i-1){1'b1}} << (p0_dnm_shift-1));

    assign S_dnm = |(aligned_num[width_i-2:0] & sticky_mask);

    always_comb begin
        if($signed({1'b0, i_shift}) <= $signed($unsigned(max_exp_elem) + $unsigned(width_o_man) - $unsigned(lz_num))) begin
            R_dnm = aligned_num[p0_dnm_shift - 1];
        end else begin
            R_dnm = 0;
        end

        if($signed({1'b0, i_shift}) < $signed($unsigned(max_exp_elem) + $unsigned(width_o_man) - $unsigned(lz_num))) begin
            p0_dnm_rnd = R_dnm && (aligned_num[p0_dnm_shift] || S_dnm);
        end else begin
            p0_dnm_rnd = R_dnm && S_dnm;
        end
    end

    logic [width_o_man-1:0] p0_man_dnm_shifted;
    logic   [width_o_man:0] p0_man_dnm_ofl;  // Extra bit to check for overflow after rounding.
    logic [width_o_man-1:0] p0_man_dnm;      // Output mantissa if output is not denormal.
    logic                   p0_exp_dnm_ofl;  // 1 if mantissa overflowed, 0 otherwise.

    assign p0_man_dnm_shifted = aligned_num >> (p0_dnm_shift);

    assign p0_man_dnm_ofl = p0_man_dnm_shifted + {{(width_o_man-1){1'b0}}, p0_dnm_rnd};

    assign p0_exp_dnm_ofl = p0_man_dnm_ofl[width_o_man];
    assign p0_man_dnm = p0_man_dnm_ofl[width_o_man-1:0];

    // Calculate output exponent, and whether output is denormal, not accounting for overflow.
    logic [width_shift+1:0] p0_exp_out;
    logic                   p0_dnm_out;   // Is output denormal?

    assign p0_exp_out = $unsigned(max_exp_elem) + $unsigned(p0_exp_nrm_ofl) - $unsigned(i_shift) - $unsigned(lz_num);
    assign p0_dnm_out = $signed($unsigned(max_exp_elem) - $unsigned(lz_num)) <= $signed({1'b0, i_shift});


    // Assign outputs.
    always_comb begin
        if(i_num != 0) begin
            if(p0_dnm_out) begin
                o_exp = p0_exp_dnm_ofl;
            end else if(p0_truncate) begin
                o_exp = max_exp_elem;
            end else begin
                o_exp = p0_exp_out;
            end

        end else begin
            o_exp = 0;
        end
    end

    always_comb begin
        if(p0_dnm_out) begin
            o_man = p0_man_dnm;
        end else if(p0_truncate) begin
            o_man = (i_num != 0) ? max_man_elem : 0;
        end else begin
            o_man = p0_man_nrm;
        end
    end

endmodule