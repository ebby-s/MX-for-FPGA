module conv_bf16tomxfp_spec_tb();

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
    localparam width_exp = 4;
    localparam width_man = 3;
    localparam bit_width = 1 + width_exp + width_man;
    localparam k = 32;
    localparam sat = 0;
    localparam e4m3_spec = 1;

    localparam max_exp_elem = (1 << width_exp) - 1 - (e4m3_spec ? 0 : 1);

    // NaN/Inf element encodings.
    localparam exp_spec = (1 << width_exp) - 1;
    localparam man_inf  = 0;
    localparam man_nan  = (1 << width_man) - 1;

    import "DPI-C" pure function shortreal bf16tomxfp8(shortreal i_bf16, int i_scale, int width_exp, int width_man, int sat, int e4m3_spec);
    import "DPI-C" pure function shortreal max_bf16(shortreal i_bf16_vec[32], int k);
    import "DPI-C" pure function int detect_nan(shortreal i_bf16_vec[32], int k);

    function shortreal mxfp8tosr(input logic [bit_width-1:0] i_mxfp8_num);

        logic [31:0] sr_bits;

        sr_bits[31]    = i_mxfp8_num[bit_width-1];
        sr_bits[30:23] = {{(8-width_exp){1'b0}}, i_mxfp8_num[bit_width-2:width_man]};
        sr_bits[22:0]  = {i_mxfp8_num[width_man-1:0], {(23-width_man){1'b0}}};

        // Interpret DUT output.
        if(e4m3_spec) begin
            if((i_mxfp8_num[bit_width-2:width_man] == exp_spec) && (i_mxfp8_num[width_man-1:0] == man_nan))
                return $bitstoreal({i_mxfp8_num[bit_width-1], 63'h7FF8000000000000});
        end else begin
            if((i_mxfp8_num[bit_width-2:width_man] == exp_spec) && (i_mxfp8_num[width_man-1:0] == man_nan))
                return $bitstoreal({i_mxfp8_num[bit_width-1], 63'h7FF8000000000000});
            else if((i_mxfp8_num[bit_width-2:width_man] == exp_spec) && (i_mxfp8_num[width_man-1:0] == man_inf))
                return $bitstoreal({i_mxfp8_num[bit_width-1], 63'h7FF0000000000000});
        end

        return $bitstoshortreal(sr_bits) * (2.0**127);

    endfunction

    function logic unsigned [7:0] exp_from_sr(input shortreal i_num);
        
        logic [31:0] num_bits;
        num_bits = $shortrealtobits(i_num);

        return num_bits[30:23];

    endfunction


    typedef logic [15:0] bf_16_vec_t [k];  // Type for vector of BF16 numbers.

    class bf16_gen;                 // Random BF16 input.
        rand logic [k-1:0] r_dnrm;  // Set individual elements to denorm.
        rand logic [k-1:0] r_zero;  // Set individual elements to zero.
    
        rand logic r_dnrm_row;    // Set entire vector to denorms.
        rand logic r_zero_row;    // Set entire vector to zeros.

        rand logic [15:0] r_bf16_vec [k];

        constraint c_dnrm_dist {
            r_dnrm dist {
            0 :/ 90,
            1 :/ 10 };
        }

        constraint c_zero_dist {
            r_zero dist {
            0 :/ 90,
            1 :/ 10 };
        }

        constraint c_dnrm_row_dist {
            r_dnrm_row dist {
            0 :/ 95,
            1 :/  5 };
        }

        constraint c_zero_row_dist {
            r_zero_row dist {
            0 :/ 95,
            1 :/  5 };
        }

        int count = 0;      // Add constraints to test interesting cases.

        function void post_randomize();
            count++;

            for(int i=0; i<k; i++) begin
                if(r_zero_row || r_zero[i]) begin
                    r_bf16_vec[i] &= 16'h8000;
                end else if(r_dnrm_row || r_dnrm[i]) begin
                    r_bf16_vec[i] &= 16'h807f;
                end
            end

        endfunction

    endclass


    // DUT
    logic          [15:0] p0_bf16_vec [32];
    logic           [7:0] p0_mx_exp_dly1;
    logic           [7:0] p0_mx_exp_dly2;
    logic           [7:0] p0_mx_exp_dly4;
    logic signed [bit_width-1:0] p0_mx_vec_dly1 [32];
    logic signed [bit_width-1:0] p0_mx_vec_dly2 [32];
    logic signed [bit_width-1:0] p0_mx_vec_dly4 [32];

    conv_bf16tomxfp_spec #(
        .exp_width(width_exp),
        .man_width(width_man),
        .k(k),
        .sat(sat),
        .e4m3_spec(e4m3_spec),
        .freq_mhz(100)
    )u0_conv(
        .i_clk(clk),
        .i_bf16_vec(p0_bf16_vec),
        .o_mx_vec(p0_mx_vec_dly1),
        .o_mx_exp(p0_mx_exp_dly1)
    );

    conv_bf16tomxfp_spec #(
        .exp_width(width_exp),
        .man_width(width_man),
        .k(k),
        .sat(sat),
        .e4m3_spec(e4m3_spec),
        .freq_mhz(200)
    )u1_conv(
        .i_clk(clk),
        .i_bf16_vec(p0_bf16_vec),
        .o_mx_vec(p0_mx_vec_dly2),
        .o_mx_exp(p0_mx_exp_dly2)
    );

    conv_bf16tomxfp_spec #(
        .exp_width(width_exp),
        .man_width(width_man),
        .k(k),
        .sat(sat),
        .e4m3_spec(e4m3_spec),
        .freq_mhz(400)
    )u2_conv(
        .i_clk(clk),
        .i_bf16_vec(p0_bf16_vec),
        .o_mx_vec(p0_mx_vec_dly4),
        .o_mx_exp(p0_mx_exp_dly4)
    );

    // Convert DUT outputs to SV types.
    int dut_scale_dly1;   // Scale outputs from DUT.
    int dut_scale_dly2;
    int dut_scale_dly4;

    real dut_out_dly1 [k];   // DUT outputs as reals.
    real dut_out_dly2 [k];
    real dut_out_dly4 [k];

    assign dut_scale_dly1 = p0_mx_exp_dly1;
    assign dut_scale_dly2 = p0_mx_exp_dly2;
    assign dut_scale_dly4 = p0_mx_exp_dly4;

    always_comb begin
        for(int j=0; j<k; j++) begin
            dut_out_dly1[j] = mxfp8tosr(p0_mx_vec_dly1[j]);
            dut_out_dly2[j] = mxfp8tosr(p0_mx_vec_dly2[j]);
            dut_out_dly4[j] = mxfp8tosr(p0_mx_vec_dly4[j]);

            // if(dut_out_dly1[j] == 32768.0) begin
            //     $display("DUT Out raw: %d", p0_mx_vec_dly1[j]);
            //     $display("DUT out sr:  %f", dut_out_dly1[j]);
            //     $display("DUT out srb: %d", $shortrealtobits(mxfp8tosr(p0_mx_vec_dly1[j])));
            // end
        end
    end

    // Reference
    real ref_in_delay    [16] [k];
    real ref_out_delay   [16] [k]; // Delay reference.
    int  ref_scale_delay [16];

    logic [15:0] ref_in [k];  // Reference signals.
    shortreal    ref_out [k];
    int          ref_scale;

    shortreal r_ref_in [k];   // Reference as reals.

    int failed;

    // Delay reference to match DUT.
    assign ref_scale_delay[0] = ref_scale;

    always_comb begin
        for(int i=0; i<k; i++) begin
            ref_in_delay[0][i]  = r_ref_in[i];
            ref_out_delay[0][i] = ref_out[i];
        end
    end

    always_ff @(posedge clk) begin
        for(int j=1; j<16; j++) begin
            ref_scale_delay[j] <= ref_scale_delay[j-1];

            for(int i=0; i<k; i++) begin
                ref_in_delay[j][i] <= ref_in_delay[j-1][i];
                ref_out_delay[j][i] <= ref_out_delay[j-1][i];
            end
        end
    end

    bf16_gen rand_gen;  // Generate shaped random input.


    initial begin
        #10

        rand_gen = new();

        $display("Starting -----");
        $display("Width Exp: %d", width_exp);
        $display("Width Man: %d", width_man);
        $display("K:         %d", k);
        $display("Saturate?: %d", sat);
        $display("E4M3 Ofl?: %d", e4m3_spec);

        for(int i=0; i<(1<<16); i++) begin
            #10 rand_gen.randomize();

            // Generate reference input, feed to DUT.
            ref_in = rand_gen.r_bf16_vec;

            for(int j=0; j<k; j++) begin
                r_ref_in[j]  = $bitstoshortreal({ref_in[j], 16'h0});
            end

            p0_bf16_vec = ref_in;

            // Calculate reference output.
            ref_scale = exp_from_sr(max_bf16(r_ref_in, k));
            if(ref_scale >= max_exp_elem) begin
                ref_scale -= max_exp_elem;
            end else begin
                ref_scale = 0;
            end

            assert(ref_scale != 8'hff);


            for(int j=0; j<k; j++) begin
                ref_out[j] = bf16tomxfp8(r_ref_in[j], ref_scale+max_exp_elem, width_exp, width_man, sat, e4m3_spec);
            end

            // Check if reference matches DUT.
            failed = 0;

            if((ref_scale_delay[1] != dut_scale_dly1) || (ref_scale_delay[3] != dut_scale_dly2) || (ref_scale_delay[5] != dut_scale_dly4))
                failed = -1;

            for(int j=0; j<k; j++) begin
                if((ref_scale_delay[1] != 8'hff) && (ref_out_delay[1][j] != dut_out_dly1[j])) begin
                    failed = j;
                    break;
                end
                if((ref_scale_delay[3] != 8'hff) && (ref_out_delay[3][j] != dut_out_dly2[j])) begin
                    failed = j;
                    break;
                end
                if((ref_scale_delay[5] != 8'hff) && (ref_out_delay[5][j] != dut_out_dly4[j])) begin
                    failed = j;
                    break;
                end
            end

            // if(i == 177) begin
            //     failed = 1;
            if(failed < 0) begin
                $display("Failed on: %d", i);
                $display("Ref in:  %d", p0_bf16_vec[0]);
                $display("Ref in:  %f", r_ref_in[0]);
                $display("DUT out: %d", dut_scale_dly1);
                $display("DUT out: %d", dut_scale_dly2);
                $display("DUT out: %d", dut_scale_dly4);
                $display("Ref out: %d  <- Mismatch!", ref_scale_delay[1]);
                $display("Ref out: %d  <- Mismatch!", ref_scale_delay[3]);
                $display("Ref out: %d  <- Mismatch!", ref_scale_delay[5]);
                $display("FAILED");
                $finish();
            end else if(failed > 0) begin
                $display("Failed on: %d", i);
                $display("Failed on: %d", failed);
                $display("Ref in:  %f", ref_in_delay[1][failed]); /* * 2.0**(127) */
                $display("Ref in:  %f", ref_in_delay[3][failed]);
                $display("Ref in:  %f", ref_in_delay[5][failed]);
                $display("DUT out: %f", dut_out_dly1[failed]);
                $display("DUT out: %f", dut_out_dly2[failed]);
                $display("DUT out: %f", dut_out_dly4[failed]);
                $display("Ref out: %f", ref_out_delay[1][failed]);
                $display("Ref out: %f", ref_out_delay[3][failed]);
                $display("Ref out: %f", ref_out_delay[5][failed]);
                $display("Ref scl: %d", ref_scale_delay[1]);
                $display("Ref scl: %d", ref_scale_delay[3]);
                $display("Ref scl: %d", ref_scale_delay[5]);
                $display("FAILED");
                $finish();
            end
        end

        $display("PASSED");
        $finish();
    end






endmodule
