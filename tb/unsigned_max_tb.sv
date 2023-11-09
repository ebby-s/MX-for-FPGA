module unsigned_max_tb (
    input logic i_clk,
    input logic i_rst_n,
    input logic unsigned [width-1:0] i_exps [length]
);

    localparam width = 8;
    localparam length = 32;

    // DUT
    logic [width-1:0] p1_e_max_comb;
    logic [width-1:0] p1_e_max_dly_1;
    logic [width-1:0] p1_e_max_dly_2;
    logic [width-1:0] p1_e_max_dly_5;

    unsigned_max #(
        .width(width),
        .length(length),
        .pl_freq(8)
    ) u0_exp_max (
        .i_clk(i_clk),
        .i_exps(i_exps),
        .o_e_max(p1_e_max)
    );

    unsigned_max #(
        .width(width),
        .length(length),
        .pl_freq(4)
    ) u1_exp_max (
        .i_clk(i_clk),
        .i_exps(i_exps),
        .o_e_max(p1_e_max_dly_1)
    );

    unsigned_max #(
        .width(width),
        .length(length),
        .pl_freq(2)
    ) u2_exp_max (
        .i_clk(i_clk),
        .i_exps(i_exps),
        .o_e_max(p1_e_max_dly_2)
    );

    unsigned_max #(
        .width(width),
        .length(length),
        .pl_freq(1)
    ) u3_exp_max (
        .i_clk(i_clk),
        .i_exps(i_exps),
        .o_e_max(p1_e_max_dly_5)
    );

    // Reference
    logic unsigned [width-1:0] p0_ref_e_max;

    always_comb begin
        ref_e_max = 0;
        for(int i=0; i<length; i++) begin
            p0_ref_e_max = p0_ref_e_max > i_exps[i] ? p0_ref_e_max : i_exps[i];
        end
    end

    for(genvar i=0; i<5; i++) begin : ref_dly
        logic [width-1:0] ref_e_max;

        always_ff @(posedge i_clk, negedge i_rst_n) begin
            if(i != 0) begin
                ref_e_max <= ref_dly[i-1].ref_e_max;
            end else begin
                ref_e_max <= p0_ref_e_max;
            end
        end
    end


    // Properties
    default clocking @(posedge i_clk); endclocking
    default disable iff (!i_rst_n);

    ast_u_max_comb: assert property(
        p1_e_max_comb == ref_e_max
    );


endmodule
