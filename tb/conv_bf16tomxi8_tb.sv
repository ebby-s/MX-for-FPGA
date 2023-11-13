module conv_bf16tomxi8_tb();

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
    localparam width_diff  = 9 - bit_width;

    import "DPI-C" pure function int shift_rnd_rne_ref(int i_num, int i_shift, int width_diff, int width_o);
    import "DPI-C" pure function int bf16tomxi8(shortreal i_bf16, int i_scale);

    function logic unsigned [7:0] exp(input logic [15:0] i_num);
        return i_num[14:7];
    endfunction

    function logic unsigned [7:0] max_exp(input logic [15:0] i_nums [k]);

        logic unsigned [7:0] e_max;

        e_max = 0;
        for (int i=0; i<k; i++)
            e_max = (exp(i_nums[i]) > e_max) ? exp(i_nums[i]) : e_max;

        return e_max;
    endfunction

    function logic [15:0] set_denorm(input logic [15:0] i_num);
        return i_num & 16'b1000000001111111;
    endfunction


    // DUT
    logic          [15:0] p0_bf16_vec [32];
    logic           [7:0] p0_mx_exp_dly1;
    logic           [7:0] p0_mx_exp_dly2;
    logic           [7:0] p0_mx_exp_dly4;
    logic signed [bit_width-1:0] p0_mx_vec_dly1 [32];
    logic signed [bit_width-1:0] p0_mx_vec_dly2 [32];
    logic signed [bit_width-1:0] p0_mx_vec_dly4 [32];

    conv_bf16tomxi8 #(
        .bit_width(bit_width),
        .k(k),
        .freq_mhz(100)
    )u0_conv(
        .i_clk(clk),
        .i_bf16_vec(p0_bf16_vec),
        .o_mx_vec(p0_mx_vec_dly1),
        .o_mx_exp(p0_mx_exp_dly1)
    );

    conv_bf16tomxi8 #(
        .bit_width(bit_width),
        .k(k),
        .freq_mhz(200)
    )u1_conv(
        .i_clk(clk),
        .i_bf16_vec(p0_bf16_vec),
        .o_mx_vec(p0_mx_vec_dly2),
        .o_mx_exp(p0_mx_exp_dly2)
    );

    conv_bf16tomxi8 #(
        .bit_width(bit_width),
        .k(k),
        .freq_mhz(400)
    )u2_conv(
        .i_clk(clk),
        .i_bf16_vec(p0_bf16_vec),
        .o_mx_vec(p0_mx_vec_dly4),
        .o_mx_exp(p0_mx_exp_dly4)
    );


    // Reference
    real        ref_out_delay   [16] [k]; // Delay reference.
    logic [7:0] ref_scale_delay [16];

    logic [15:0] ref_in [k];  // Reference signals.
    int          ref_out [k];
    int          ref_scale;

    shortreal r_ref_in [k];   // Reference as reals.
    real      r_ref_out [k];

    int dut_scale_dly1;   // Scale outputs from DUT.
    int dut_scale_dly2;
    int dut_scale_dly4;

    real r_dut_out_dly1 [k];   // DUT outputs as reals.
    real r_dut_out_dly2 [k];
    real r_dut_out_dly4 [k];

    int failed;

    // Delay reference to match DUT.
    assign ref_scale_delay[0] = ref_scale;

    always_comb begin
        for(int i=0; i<k; i++) begin
            ref_out_delay[0][i] = r_ref_out[i];
        end
    end

    always_ff @(posedge clk) begin
        for(int j=1; j<16; j++) begin
            ref_scale_delay[j] <= ref_scale_delay[j-1];

            for(int i=0; i<k; i++) begin
                ref_out_delay[j][i] <= ref_out_delay[j-1][i];
            end
        end
    end


    initial begin
        #10

        $display("Starting -----");

        for(int i=0; i<(1<<16); i++) begin
            #10

            // Generate reference input, feed to DUT.
            for(int j=0; j<k; j++) begin
                // if(!($random&32'h7)) begin
                //     ref_in[j] = set_denorm($random);
                // end else begin
                    ref_in[j] = $random;
                // end
                r_ref_in[j]  = $bitstoshortreal({ref_in[j], 16'h0});
            end

            p0_bf16_vec = ref_in;

            // Calculate reference output.
            ref_scale = max_exp(ref_in);

            for(int j=0; j<k; j++) begin
                ref_out[j] = bf16tomxi8(r_ref_in[j], ref_scale);
                r_ref_out[j] = $itor(ref_out[j]) *(2.0**-(bit_width-2.0));
            end

            // Get DUT outputs.
            dut_scale_dly1 = p0_mx_exp_dly1;
            dut_scale_dly2 = p0_mx_exp_dly2;
            dut_scale_dly4 = p0_mx_exp_dly4;
            for(int j=0; j<k; j++) begin
                r_dut_out_dly1[j] = $itor(p0_mx_vec_dly1[j]) *(2.0**-(bit_width-2.0));
                r_dut_out_dly2[j] = $itor(p0_mx_vec_dly2[j]) *(2.0**-(bit_width-2.0));
                r_dut_out_dly4[j] = $itor(p0_mx_vec_dly4[j]) *(2.0**-(bit_width-2.0));
            end

            // Check if reference matches DUT.
            failed = 0;

            if((ref_scale_delay[1] != dut_scale_dly1) || (ref_scale_delay[3] != dut_scale_dly2) || (ref_scale_delay[5] != dut_scale_dly4))
                failed = -1;
            
            for(int j=0; j<k; j++) begin
                if((ref_out_delay[1][j] != r_dut_out_dly1[j]) || (ref_out_delay[3][j] != r_dut_out_dly2[j]) || (ref_out_delay[5][j] != r_dut_out_dly4[j])) begin
                    failed = j;
                    break;
                end
            end

            if(failed < 0) begin
                $display("Ref in:  %f", p0_bf16_vec[0]);
                $display("Ref in:  %f", r_ref_in[0]);
                $display("DUT out: %d", dut_scale_dly1);
                $display("DUT out: %d", dut_scale_dly2);
                $display("DUT out: %d", dut_scale_dly4);
                $display("Ref out: %d  <- Mismatch!", ref_scale_delay[1]);
                $display("Ref out: %d  <- Mismatch!", ref_scale_delay[4]);
                $display("Ref out: %d  <- Mismatch!", ref_scale_delay[5]);
                $display("FAILED");
                $finish();
            end else if(failed > 0) begin
                $display("Failed on: %d", i);
                $display("Failed on: %d", failed);
                $display("Ref in:  %f", p0_bf16_vec[failed]);
                $display("Ref in:  %f", r_ref_in[failed]);
                $display("DUT out: %f", r_dut_out_dly1[failed]);
                $display("DUT out: %f", r_dut_out_dly2[failed]);
                $display("DUT out: %f", r_dut_out_dly4[failed]);
                $display("Ref out: %f", ref_out_delay[1][failed]);
                $display("Ref out: %f", ref_out_delay[3][failed]);
                $display("Ref out: %f", ref_out_delay[5][failed]);
                $display("Ref scl: %d", ref_scale);
                $display("FAILED");
                $finish();
            end
        end

        $display("PASSED");
        $finish();
    end






endmodule
