module conv_fitobf16_tb #(
    parameter bit_width = 21
)();

    import "DPI-C" pure function real conv_fitobf16_ref(int i_fi_num, int bit_width);

    // DUT
    logic [bit_width-1:0]   fi_num;
    logic          [15:0] bf16_num;

    conv_fitobf16 # (
        .bit_width(bit_width)
    ) u_conv (
        .i_fi_num(fi_num),
        .o_bf16(bf16_num)
    );


    // Reference
    logic signed [bit_width-1:0] ref_in;
    real ref_out;

    real r_dut_out;

    longint i;

    initial begin
        #1;
        $display("Starting -----");
        $display("Width: %d", bit_width);

        i = 1;

        for(i=0; i<(1<<(bit_width+1)); i++) begin

            ref_in  = i;
            ref_out = conv_fitobf16_ref(ref_in, bit_width);

            fi_num = ref_in;
            #10
            r_dut_out = $bitstoshortreal({bf16_num, 16'h0});


            if((ref_out != r_dut_out) || $isunknown(bf16_num)) begin
                $display("Ref in:  %f", ref_in);
                $display("DUT out: %f", r_dut_out);
                $display("DUT raw: %d", bf16_num);
                $display("Ref out: %f  <- Mismatch!", ref_out);
                $display("FAILED");
                $finish();
            end
        end

        $display("PASSED");
        $finish();
    end


endmodule
