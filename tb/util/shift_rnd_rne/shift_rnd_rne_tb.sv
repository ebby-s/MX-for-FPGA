module shift_rnd_rne_tb #(
    parameter width_i     = 9,
    parameter width_o     = 8,
    parameter width_shift = 8
)();

    localparam width_diff  = width_i - width_o;

    import "DPI-C" pure function int shift_rnd_rne_ref(int i_num, int i_shift, int width_diff, int width_o);


    // DUT
    logic signed       [width_i-1:0] p0_num;
    logic unsigned [width_shift-1:0] p0_shift;
    logic signed       [width_o-1:0] p0_rnd_out;

    shift_rnd_rne # (
        .width_i(width_i),
        .width_o(width_o),
        .width_shift(width_shift)
    ) u0_shift_rnd (
        .i_num(p0_num),
        .i_shift(p0_shift),
        .o_rnd(p0_rnd_out)
    );


    // Reference
    logic signed [width_i-1:0] ref_in;
    int ref_out;
    int ref_shift;

    real r_ref_in;
    real r_ref_out;
    real r_dut_out;

    int i;
    int j;

    initial begin
        #1;
        $display("Starting -----");
        $display("Width in:  %d", width_i);
        $display("Width out: %d", width_o);

        for(i=0; i<(1<<width_i); i++) begin
            for(j=0; j<(1<<width_shift); j++) begin

                ref_in  = i;
                ref_shift = j;
                ref_out = shift_rnd_rne_ref(ref_in, ref_shift, width_diff, width_o);

                r_ref_in  = $itor(ref_in) *(2.0**-(width_i-2.0));
                r_ref_out = $itor(ref_out)*(2.0**-(width_o-2.0));

                p0_num = ref_in;
                p0_shift = ref_shift;
                #10
                r_dut_out = $itor(p0_rnd_out)*(2.0**-(width_o-2.0));

                if((r_ref_out != r_dut_out) || $isunknown(p0_rnd_out)) begin
                    $display("Ref in:  %d", ref_in);
                    $display("Ref in:  %f", r_ref_in);
                    $display("Shift:   %d", p0_shift);
                    $display("DUT out: %f", r_dut_out);
                    $display("Ref out: %f  <- Mismatch!", r_ref_out);
                    $display("FAILED");
                    $finish();
                end
            end
        end

        $display("PASSED");
        $finish();
    end


endmodule
