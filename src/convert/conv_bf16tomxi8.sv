module conv_bf16tomxi8 #(
    parameter bit_width = 8,   // Output int bit width.
    parameter k = 32,          // Length of input vector.
    parameter freq_mhz = 400   // Target frequency, [0, 400].
)(
    input  logic i_clk,

    input  logic          [15:0] i_bf16_vec [k],
    output logic [bit_width-1:0] o_mx_vec   [k],
    output logic           [7:0] o_mx_exp
);

    localparam pl_pre_shift_rnd = freq_mhz > 200 ? 1 : 0;   // Insert flops before u_shift_rnd.
    localparam max_flop_output = freq_mhz > 100 ? 1 : 0;    // Add output flops after u_exp_max.
    localparam max_pl_freq  = (freq_mhz > 200) ? 2 :        // Insert flops within u_exp_max.
                             ((freq_mhz > 100) ? 4 : 8);
    // Number of pipeline stages in u_exp_max.
    localparam max_pl_depth = ($clog2(k) / max_pl_freq) + max_flop_output;

    // Split input into sgn, exp, man fields.
    logic                p0_sgns [k];
    logic unsigned [7:0] p0_exps [k];
    logic unsigned [6:0] p0_mans [k];

    always_comb begin
        for (int i=0; i<k; i++) begin
            p0_sgns[i] = i_bf16_vec[i][15];
            p0_exps[i] = i_bf16_vec[i][14:7];
            p0_mans[i] = i_bf16_vec[i][6:0];
        end
    end

    // Find E_max, the largest exponent in inputs.
    logic [7:0] p1_e_max;

    unsigned_max #(
        .width(8),
        .length(k),
        .pl_freq(max_pl_freq),
        .flop_output(max_flop_output)
    ) u0_exp_max (
        .i_clk(i_clk),
        .i_exps(p0_exps),
        .o_e_max(p1_e_max)
    );

    // Flop inputs to match delay of max component.
    logic                p1_sgns [k];
    logic unsigned [7:0] p1_exps [k];
    logic unsigned [6:0] p1_mans [k];

    if(max_pl_depth != 0) begin

        for(genvar i=0; i<max_pl_depth; i++) begin : max_dly
            logic [15:0] p0_bf16_vec [k];

            for(genvar j=0; j<k; j++) begin
                if(i != 0) begin
                    always_ff @(posedge i_clk) begin
                        p0_bf16_vec[j] <= max_dly[i-1].p0_bf16_vec[j];
                    end

                end else begin
                    always_ff @(posedge i_clk) begin
                        p0_bf16_vec[j] <= i_bf16_vec[j];
                    end
                end
            end
        end

        always_comb begin
            for (int i=0; i<k; i++) begin
                p1_sgns[i] = max_dly[max_pl_depth-1].p0_bf16_vec[i][15];
                p1_exps[i] = max_dly[max_pl_depth-1].p0_bf16_vec[i][14:7];
                p1_mans[i] = max_dly[max_pl_depth-1].p0_bf16_vec[i][6:0];
            end
        end

    end else begin
        always_comb begin
            for (int i=0; i<k; i++) begin
                p1_sgns[i] = i_bf16_vec[i][15];
                p1_exps[i] = i_bf16_vec[i][14:7];
                p1_mans[i] = i_bf16_vec[i][6:0];
            end
        end
    end

    // Append implicit 1s and convert to 2's complement signed.
    logic [7:0] p1_extend_mans [k];  // Append implicit 1.
    logic [8:0] p1_signed_mans [k];  // Apply sign.

    always_comb begin
        for (int i=0; i<k; i++) begin
            p1_extend_mans[i] = {|p1_exps[i], p1_mans[i]};
            p1_signed_mans[i] = p1_sgns[i] ? -p1_extend_mans[i] : p1_extend_mans[i];
        end
    end

    // Second pipeline stage. Calculate amount to shift by.
    logic [7:0] p2_e_max;
    logic [8:0] p2_signed_mans [k];
    logic [7:0] p2_d_shifts    [k];

    if(pl_pre_shift_rnd) begin
        always_ff @(posedge i_clk) begin
            p2_e_max <= p1_e_max;

            for (int i=0; i<k; i++) begin
                p2_signed_mans[i] <= p1_signed_mans[i];
                p2_d_shifts[i]    <= p1_e_max - p1_exps[i];
            end
        end

    end else begin
        assign p2_e_max = p1_e_max;

        for (genvar i=0; i<k; i++) begin
            assign p2_signed_mans[i] = p1_signed_mans[i];
            assign p2_d_shifts[i]    = p1_e_max - p1_exps[i];
        end
    end

    // Shift and round output elements.
    logic [bit_width-1:0] p2_elems [k];

    for(genvar i=0; i<k; i++) begin
        shift_rnd_rne # (
            .width_i(9),
            .width_o(bit_width),
            .width_shift(8)
        ) u0_shift_rnd (
            .i_num(p2_signed_mans[i]),
            .i_shift(p2_d_shifts[i]),
            .o_rnd(p2_elems[i])
        );
    end

    // Assign outputs.
    always_ff @(posedge i_clk) begin
        o_mx_exp <= p2_e_max;

        for (int i=0; i<k; i++) begin
            o_mx_vec[i] <= p2_elems[i];
        end
    end

endmodule
