module dot_fp_spec_tb();

    // Generate clock and reset.
    logic clk;
    logic rst_n;

    initial begin
        clk = 0;
        forever
            #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #10
        rst_n = 1;
    end

    // Parameters and functions.
    localparam exp_width = 4;
    localparam man_width = 3;
    localparam k         = 32;
    localparam e4m3_spec = 1;
    localparam bit_width = 1 + exp_width + man_width;
    localparam fi_width  = man_width + 2;
    localparam prd_width = 2 * ((1<<exp_width) + man_width);
    localparam out_width = prd_width + $clog2(k);

    function shortreal fp6tosr(input logic [bit_width-1:0] i_fp8_num);

        logic [31:0] sr_bits;

        if(e4m3_spec) begin
            if(&i_fp8_num[bit_width-2:0])
                return $bitstoreal(64'h7FF8000000000000);
        end else begin
            if(&i_fp8_num[bit_width-2:man_width])
                return $bitstoreal(64'h7FF8000000000000);
        end

        sr_bits[31]    = i_fp8_num[bit_width-1];
        sr_bits[30:23] = {{(8-exp_width){1'b0}}, i_fp8_num[bit_width-2:man_width]};
        sr_bits[22:0]  = {i_fp8_num[man_width-1:0], {(23-man_width){1'b0}}};

        return $bitstoshortreal(sr_bits) * (2.0**127);

    endfunction

    function logic is_nan(input shortreal i_num);
        logic [31:0] sr_bits;
        logic exp_spec;
        logic man_nan;

        sr_bits = $shortrealtobits(i_num);
        exp_spec = (sr_bits[30:23] == 8'hff);
        man_nan = |sr_bits[22:0];

        return exp_spec && man_nan;
    endfunction

    // DUT
    logic signed [bit_width-1:0] i_op0 [k];
    logic signed [bit_width-1:0] i_op1 [k];
    logic signed [out_width-1:0] p0_dp_out;
    logic dut_nan;

    dot_fp_spec #(
        .exp_width(exp_width),
        .man_width(man_width),
        .k(k),
        .e4m3_spec(e4m3_spec)
    ) u_dot (
        .i_vec_a(i_op0),
        .i_vec_b(i_op1),
        .o_dp(p0_dp_out),
        .o_nan(dut_nan)
    );


    // Reference
    int ref_nan;
    real ref_dp_out;

    real r_dut_out;


    initial begin
        #10

        $display("Starting -----");
        $display("Width Exp: %d", exp_width);
        $display("Width Man: %d", man_width);
        $display("K:         %d", k);

        for(int i=0; i<(1<<16); i++) begin

            for(int j=0; j<k; j++) begin
                i_op0[j] = $random;
                i_op1[j] = $random;
            end

            ref_dp_out = 0;
            ref_nan = 0;
            for(int j=0; j<k; j++) begin
                ref_nan |= is_nan(fp6tosr(i_op0[j])) || is_nan(fp6tosr(i_op1[j]));
                ref_dp_out += fp6tosr(i_op0[j]) * fp6tosr(i_op1[j]) / (fp6tosr(1) * fp6tosr(1));
            end

            #10

            r_dut_out = p0_dp_out;

            if((r_dut_out != ref_dp_out) || (dut_nan != ref_nan)) begin
                $display("Ref in:  %f", fp6tosr(i_op0[0]));
                $display("Ref in:  %f", fp6tosr(i_op1[0]));
                $display("Ref in:  %f", fp6tosr(i_op0[1]));
                $display("Ref in:  %f", fp6tosr(i_op1[1]));
                $display("Ref in:  %f", fp6tosr(i_op0[2]));
                $display("Ref in:  %f", fp6tosr(i_op1[2]));
                $display("Ref in:  %f", fp6tosr(i_op0[3]));
                $display("Ref in:  %f", fp6tosr(i_op1[3]));
                $display("Failed on: %d", i);
                $display("DUT out: %f", r_dut_out);
                $display("Ref out: %f", ref_dp_out);
                $display("FAILED");
                $finish();
            end
        end

        $display("PASSED");
        $finish();
    end






endmodule
