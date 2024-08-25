module mul_fp_tb();

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
    localparam exp_width = 5;
    localparam man_width = 2;
    localparam bit_width = 1 + exp_width + man_width;
    localparam fi_width = man_width + 2;
    localparam prd_width = 2 * ((1<<exp_width) + man_width);

    function shortreal fp6tosr(input logic [bit_width-1:0] i_fp6_num);

        logic [31:0] sr_bits;

        sr_bits[31]    = i_fp6_num[bit_width-1];
        sr_bits[30:23] = {{(8-exp_width){1'b0}}, i_fp6_num[bit_width-2:man_width]};
        sr_bits[22:0]  = {i_fp6_num[man_width-1:0], {(23-man_width){1'b0}}};

        return $bitstoshortreal(sr_bits) * (2.0**127);

    endfunction

    // DUT
    logic signed [bit_width-1:0] dut_op0;
    logic signed [bit_width-1:0] dut_op1;
    logic signed [prd_width-1:0] dut_prd;

    mul_fp #(
        .exp_width(exp_width),
        .man_width(man_width)
    ) u_mul (
        .i_op0(dut_op0),
        .i_op1(dut_op1),
        .o_prd(dut_prd)
    );


    // Reference
    real ref_prd;

    real r_dut_prd;

    int i;
    int j;

    initial begin
        #10

        $display("Starting -----");
        $display("Width Exp: %d", exp_width);
        $display("Width Man: %d", man_width);

        i = 12;
        j = 124;

        for(i=0; i<(1<<(bit_width)); i++) begin
            for(j=0; j<(1<<(bit_width)); j++) begin

                dut_op0 = i;
                dut_op1 = j;

                ref_prd = fp6tosr(dut_op0) * fp6tosr(dut_op1) / (fp6tosr(1) * fp6tosr(1));

                #10

                r_dut_prd = dut_prd;

                if(r_dut_prd != ref_prd) begin
                    $display("Ref op0: %d", dut_op0);
                    $display("Ref op1: %d", dut_op1);
                    $display("Ref op0: %f", fp6tosr(dut_op0));
                    $display("Ref op1: %f", fp6tosr(dut_op1));
                    $display("DUT out: %d", dut_prd);
                    $display("DUT out: %f", r_dut_prd);
                    $display("Ref out: %f", ref_prd);
                    $display("FAILED");
                    $finish();
                end
            end
        end

        $display("PASSED");
        $finish();
    end






endmodule
