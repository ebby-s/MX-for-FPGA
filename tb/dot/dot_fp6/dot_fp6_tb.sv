module dot_fp6_tb();

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
    localparam bit_width = 1 + exp_width + man_width;
    localparam fi_width  = man_width + 2;
    localparam prd_width = 2 * ((1<<exp_width) + man_width);
    localparam out_width = prd_width + $clog2(k);

    function shortreal fp6tosr(input logic [bit_width-1:0] i_fp6_num);

        logic [31:0] sr_bits;

        sr_bits[31]    = i_fp6_num[bit_width-1];
        sr_bits[30:23] = {{(8-exp_width){1'b0}}, i_fp6_num[bit_width-2:man_width]};
        sr_bits[22:0]  = {i_fp6_num[man_width-1:0], {(23-man_width){1'b0}}};

        return $bitstoshortreal(sr_bits) * (2.0**127);

    endfunction

    // DUT
    logic signed [bit_width-1:0] i_op0 [k];
    logic signed [bit_width-1:0] i_op1 [k];
    logic signed [out_width-1:0] p0_dp_out;

    dot_fp6 #(
        .exp_width(exp_width),
        .man_width(man_width),
        .k(k)
    ) u_dot (
        .i_vec_a(i_op0),
        .i_vec_b(i_op1),
        .o_dp(p0_dp_out)
    );


    // Reference
    real ref_dp_out;


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
            for(int j=0; j<k; j++) begin
                ref_dp_out += fp6tosr(i_op0[j]) * fp6tosr(i_op1[j]) / (fp6tosr(1) * fp6tosr(1));
            end

            #10

            if(p0_dp_out != ref_dp_out) begin
                $display("Ref in:  %f", fp6tosr(i_op0[0]));
                $display("Ref in:  %f", fp6tosr(i_op1[0]));
                $display("Ref in:  %f", fp6tosr(i_op0[1]));
                $display("Ref in:  %f", fp6tosr(i_op1[1]));
                $display("Ref in:  %f", fp6tosr(i_op0[2]));
                $display("Ref in:  %f", fp6tosr(i_op1[2]));
                $display("Ref in:  %f", fp6tosr(i_op0[3]));
                $display("Ref in:  %f", fp6tosr(i_op1[3]));
                $display("Failed on: %d", i);
                $display("DUT out: %d", p0_dp_out);
                $display("Ref out: %f", ref_dp_out);
                $display("FAILED");
                $finish();
            end
        end

        $display("PASSED");
        $finish();
    end






endmodule
