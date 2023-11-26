module fp_rnd_nan_rne_tb #(
    parameter width_i     = 8,
    parameter width_o_exp = 5,
    parameter width_o_man = 2,
    parameter width_shift = 8,
    parameter sat = 1,
    parameter e4m3_spec = 0
)();


    // NaN/Inf element encodings.
    localparam exp_spec = (1 << width_o_exp) - 1;
    localparam man_inf  = 0;
    localparam man_nan  = (1 << width_o_man) - 1;

    import "DPI-C" pure function shortreal fp_rnd_rne_ref(int i_num, int i_shift, int i_nan, int width_exp, int width_man, int sat, int e4m3_spec);
    // import "DPI-C" pure function int compare_ref_dut(shortreal ref_out, shortreal dut_out);

    function logic is_nan(input shortreal i_num);
        logic [31:0] sr_bits;
        logic exp_spec;
        logic man_nan;

        sr_bits = $shortrealtobits(i_num);
        exp_spec = (sr_bits[30:23] == 8'hff);
        man_nan = |sr_bits[22:0];

        return exp_spec && man_nan;
    endfunction

    function logic is_inf(input shortreal i_num);
        logic [31:0] sr_bits;
        logic exp_spec;
        logic man_nan;

        sr_bits = $shortrealtobits(i_num);
        exp_spec = (sr_bits[30:23] == 8'hff);
        man_nan = |sr_bits[22:0];

        return exp_spec && ~man_nan;
    endfunction

    function logic compare_ref_dut(input shortreal i_ref_out, input shortreal i_dut_out);

        if(is_nan(i_ref_out) != is_nan(i_dut_out)) begin
            return 1;
        end else if(is_inf(i_ref_out) != is_inf(i_dut_out)) begin
            return 1;
        end else if((is_nan(i_ref_out) != 0) || (is_inf(i_dut_out) != 0)) begin
            return 0;
        end 

        return (i_ref_out != i_dut_out);

    endfunction


    // DUT
    logic signed       [width_i-1:0] p0_num;
    logic unsigned [width_shift-1:0] p0_shift;
    logic                            p0_nan;
    logic          [width_o_exp-1:0] p0_exp;
    logic          [width_o_man-1:0] p0_man;

    fp_rnd_nan_rne # (
        .width_i(width_i),
        .width_o_exp(width_o_exp),
        .width_o_man(width_o_man),
        .width_shift(width_shift),
        .sat(sat),
        .e4m3_spec(e4m3_spec)
    ) u0_fp_rnd (
        .i_num(p0_num),
        .i_shift(p0_shift),
        .i_nan(p0_nan),
        .o_exp(p0_exp),
        .o_man(p0_man)
    );


    // Reference
    logic unsigned [width_i-1:0] ref_in;
    int ref_shift;
    logic ref_nan;
    real ref_out;

    real r_dut_out;

    int i;
    int j;
    int l;

    initial begin
        #1;
        $display("Starting -----");
        $display("Width Exp: %d", width_o_exp);
        $display("Width Man: %d", width_o_man);
        $display("Saturate?: %d", sat);
        $display("E4M3 Ofl?: %d", e4m3_spec);

        // i = 233;
        // j = 0;
        // l = 0;

        for(i=0; i<(1<<(width_i+1)); i++) begin
            for(j=0; j<(1<<width_shift); j++) begin
                for(l=0; l<2; l++) begin

                    // Calculate reference signals.
                    ref_in  = i;
                    ref_shift = j;
                    ref_nan = l;
                    ref_out = fp_rnd_rne_ref(ref_in, ref_shift, ref_nan, width_o_exp, width_o_man, sat, e4m3_spec);

                    // Send input to DUT.
                    p0_num = ref_in;
                    p0_shift = ref_shift;
                    p0_nan = ref_nan;
                    #10

                    // Interpret DUT output.
                    if(p0_exp != 0) begin
                        r_dut_out = {2'h01, p0_man};
                    end else begin
                        r_dut_out = {2'h00, p0_man}*2.0;
                    end

                    if(p0_exp >= width_o_man) begin
                        r_dut_out *= 2.0**(p0_exp-width_o_man);
                    end else begin
                        r_dut_out /= 2.0**(width_o_man-p0_exp);
                    end

                    if(e4m3_spec) begin
                        if((p0_exp == exp_spec) && (p0_man == man_nan))
                            r_dut_out = $bitstoreal(64'h7FF8000000000000);
                    end else begin
                        if((p0_exp == exp_spec) && (p0_man == man_nan))
                            r_dut_out = $bitstoreal(64'h7FF8000000000000);
                        else if((p0_exp == exp_spec) && (p0_man == man_inf))
                            r_dut_out = $bitstoreal(64'h7FF0000000000000);
                    end

                    if(compare_ref_dut(ref_out, r_dut_out) || $isunknown({p0_exp, p0_man})) begin
                        $display("Ref in:  %f", ref_in);
                        $display("Shift:   %d", ref_shift);
                        $display("NaNIn:   %d", ref_nan);
                        $display("DUT out: %f", r_dut_out);
                        $display("DUT exp: %d", p0_exp);
                        $display("DUT man: %d", p0_man);
                        $display("Ref out: %f  <- Mismatch!", ref_out);
                        $display("Ref bit: %d  <- Mismatch!", $realtobits(ref_out));
                        $display("FAILED");
                        $finish();
                    end
                end
            end
        end

        $display("PASSED");
        $finish();
    end


endmodule
