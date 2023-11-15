module fp_rnd_rne_tb #(
    parameter width_i     = 8,
    parameter width_o_exp = 5,
    parameter width_o_man = 2,
    parameter width_shift = 8
)();


    import "DPI-C" pure function shortreal fp_rnd_rne_ref(int i_num, int i_shift, int width_exp, int width_man);


    // DUT
    logic signed       [width_i-1:0] p0_num;
    logic unsigned [width_shift-1:0] p0_shift;
    logic          [width_o_exp-1:0] p0_exp;
    logic          [width_o_man-1:0] p0_man;

    fp_rnd_rne # (
        .width_i(width_i),
        .width_o_exp(width_o_exp),
        .width_o_man(width_o_man),
        .width_shift(width_shift)
    ) u0_fp_rnd (
        .i_num(p0_num),
        .i_shift(p0_shift),
        .o_exp(p0_exp),
        .o_man(p0_man)
    );


    // Reference
    logic unsigned [width_i-1:0] ref_in;
    int ref_shift;
    real ref_out;

    real r_dut_out;

    int i;
    int j;

    initial begin
        #1;
        $display("Starting -----");

        i = 1;
        j = 0;

        for(i=0; i<(1<<(width_i+1)); i++) begin
            for(j=0; j<(1<<width_shift); j++) begin

                ref_in  = i;
                ref_shift = j;
                ref_out = fp_rnd_rne_ref(ref_in, ref_shift, width_o_exp, width_o_man);

                p0_num = ref_in;
                p0_shift = ref_shift;
                #10
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

                if((ref_out != r_dut_out) || $isunknown({p0_exp, p0_man})) begin
                    $display("Ref in:  %f", ref_in);
                    $display("Shift:   %d", ref_shift);
                    $display("DUT out: %f", r_dut_out);
                    $display("DUT exp: %d", p0_exp);
                    $display("DUT man: %d", p0_man);
                    $display("Ref out: %f  <- Mismatch!", ref_out);
                    $display("FAILED");
                    $finish();
                end
            end
        end

        $display("PASSED");
        $finish();
    end


endmodule
