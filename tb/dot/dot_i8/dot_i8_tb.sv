module dot_int_tb();

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
    localparam bit_width = 8;
    localparam k = 32;
    localparam out_width = 2*bit_width + $clog2(k);

    // DUT
    logic signed [bit_width-1:0] i_op0 [k];
    logic signed [bit_width-1:0] i_op1 [k];
    logic signed [out_width-1:0] p0_dp_out;

    dot_int #(
        .bit_width(bit_width),
        .k(k)
    ) u0_dop_i8 (
        .i_vec_a(i_op0),
        .i_vec_b(i_op1),
        .o_dp(p0_dp_out)
    );


    // Reference
    int ref_dp_out;


    initial begin
        #10

        $display("Starting -----");
        $display("Width Exp: %d", bit_width);
        $display("K:         %d", k);

        for(int i=0; i<(1<<18); i++) begin

            for(int j=0; j<k; j++) begin
                i_op0[j] = $random;
                i_op1[j] = $random;
            end

            ref_dp_out = 0;
            for(int j=0; j<k; j++) begin
                ref_dp_out += $signed(i_op0[j]) * $signed(i_op1[j]);
            end

            #10

            if(p0_dp_out != ref_dp_out) begin
                $display("Ref in:  %d", i_op0[0]);
                $display("Ref in:  %d", i_op1[0]);
                $display("Ref in:  %d", i_op0[1]);
                $display("Ref in:  %d", i_op1[1]);
                $display("Ref in:  %d", i_op0[2]);
                $display("Ref in:  %d", i_op1[2]);
                $display("Ref in:  %d", i_op0[3]);
                $display("Ref in:  %d", i_op1[3]);
                $display("Failed on: %d", i);
                $display("DUT out: %d", p0_dp_out);
                $display("Ref out: %d", ref_dp_out);
                $display("FAILED");
                $finish();
            end
        end

        $display("PASSED");
        $finish();
    end






endmodule
