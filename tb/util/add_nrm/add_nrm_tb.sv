module add_nrm_tb #(
    parameter int_w = 8,
    parameter scale_w = 8
)();

    // Parameters and functions.
    localparam ref_w = int_w + 80;   // Accommodates aligned sums for test scale differences up to ~64.

    function shortreal fptosr(input logic [int_w-1:0] mant, input logic [scale_w-1:0] scale);

        logic [31:0] sr_bits;

        sr_bits[31]    = mant[int_w-1];
        sr_bits[30:23] = {{(8-scale_w){1'b0}}, scale};
        sr_bits[22:0]  = {mant[int_w-2:0], {(23-int_w+1){1'b0}}};

        return $bitstoshortreal(sr_bits);

    endfunction

    // Magnitude of an operand, and its sign bit.
    function automatic logic [ref_w-1:0] ref_mag(input logic [int_w-1:0] op,
                                                 input logic [scale_w-1:0] scale,
                                                 input logic imp);
        logic [int_w-1:0] mag_int;

        if(imp) begin
            ref_mag = (scale != 0) ? ((1 << (int_w-1)) | op[int_w-2:0]) : (op[int_w-2:0] << 1);
        end else begin
            mag_int = op[int_w-1] ? (-op) : op;
            ref_mag = mag_int;
        end

        return ref_mag;

    endfunction


    // Exact reference: round-to-nearest-even shared-exponent addition.
    // Mantissa mode: value = ±(1.f / sub-normal) * 2^(scale - 127 - (int_w-1)).
    // Integer mode:  value = ±op * 2^scale.
    // Output: sign | fraction with the implicit 1 not stored, exact zero encoded as 0e0.
    // r_skip is set for remainder combinations the fixed point cannot decide exactly.
    task ref_add(input logic [int_w-1:0] op0, input logic [scale_w-1:0] s0,
                 input logic [int_w-1:0] op1, input logic [scale_w-1:0] s1, input logic imp,
                 output logic r_skip,
                 output logic [int_w-1:0] r_out, output logic [scale_w-1:0] r_scale);
        logic [ref_w-1:0] m0, m1, m_sum, one, dropped, half;
        logic [scale_w-1:0] smin, diff;
        logic g0, g1, sgn, s_bit;
        logic [int_w:0] sig;
        logic [3:0] frac_win;
        integer sh;

        one = 1;

        g0 = op0[int_w-1];
        g1 = op1[int_w-1];
        m0 = ref_mag(op0, s0, imp);
        m1 = ref_mag(op1, s1, imp);

        smin = (s0 < s1) ? s0 : s1;
        diff = (s0 > s1) ? s0 - s1 : s1 - s0;

        // Remainder lost below the fixed-point window.
        s_bit = (diff > 3) && (((s0 > s1) ? m1 : m0) & ((1 << (diff-3))-1)) != 0;

        // Align to the smaller scale and add.
        m_sum = ((g0 ? -m0 : m0) <<< (s0 - smin)) + ((g1 ? -m1 : m1) <<< (s1 - smin));

        sgn = m_sum[ref_w-1];
        m_sum = sgn ? -m_sum : m_sum;

        if(m_sum == 0) begin
            r_skip = 0;
            r_out = '0;
            r_scale = '0;
        end else begin
            // Normalise: shift so the significand fills int_w bits with the leading 1 at int_w-1.
            sh = 0;
            while((m_sum >> sh) > ((1 << int_w) - 1)) begin
                sh++;
            end
            while(m_sum < (1 << (int_w-1)) && sh > -40) begin
                m_sum = m_sum <<< 1;
                sh--;
            end

            if(sh > 0) begin
                dropped = m_sum & ((one << sh)-1);
                half = one << (sh-1);
                sig = (1 << (int_w-1)) | ((m_sum >> sh) & ((1 << (int_w-1))-1));
                if(dropped > half || (dropped == half && sig[0])) begin
                    sig = sig + 1;
                end
            end else begin
                sig = m_sum[int_w-1:0];
            end

            if(sig == (1 << int_w)) begin
                sig = sig >> 1;
                sh = sh + 1;
            end

            r_out = {sgn, sig[int_w-2:0]};
            r_scale = (sh + smin) & ((1 << scale_w)-1);

            // Remainder combinations the fixed point cannot decide exactly.
            frac_win = (sh >= 4) ? ((m_sum >> (sh-4)) & 4'b1111) : '0;
            r_skip = (imp == 0) ? s_bit : (sgn && s_bit && (frac_win == 4'b1000 || frac_win == 4'b1001));
        end
    endtask


    // DUTs: mantissa mode (default) and integer mode.
    logic signed [int_w-1:0] i_op0;
    logic signed [int_w-1:0] i_op1;
    logic unsigned [scale_w-1:0] i_scale0;
    logic unsigned [scale_w-1:0] i_scale1;

    logic   [int_w-1:0] out;
    logic [scale_w-1:0] o_scale;

    logic   [int_w-1:0] out_int;
    logic [scale_w-1:0] o_scale_int;

    add_nrm #(
        .int_w(int_w),
        .scale_w(scale_w)
    ) u0_add_nrm (
        .i_op0(i_op0),
        .i_op1(i_op1),
        .i_scale0(i_scale0),
        .i_scale1(i_scale1),
        .out(out),
        .o_scale(o_scale)
    );

    add_nrm #(
        .int_w(int_w),
        .scale_w(scale_w),
        .implicit_man(0)
    ) u1_add_nrm (
        .i_op0(i_op0),
        .i_op1(i_op1),
        .i_scale0(i_scale0),
        .i_scale1(i_scale1),
        .out(out_int),
        .o_scale(o_scale_int)
    );


    // Apply a vector and compare both DUT modes against the reference.
    task test_vector(input logic [int_w-1:0] op0, input logic [scale_w-1:0] s0,
                     input logic [int_w-1:0] op1, input logic [scale_w-1:0] s1);
        logic fp_skip, int_skip;
        logic [int_w-1:0] fp_out, int_out;
        logic [scale_w-1:0] fp_scale, int_scale;

        ref_add(op0, s0, op1, s1, 1, fp_skip, fp_out, fp_scale);
        ref_add(op0, s0, op1, s1, 0, int_skip, int_out, int_scale);

        i_op0 = op0;
        i_op1 = op1;
        i_scale0 = s0;
        i_scale1 = s1;
        #1;

        if(!fp_skip && ({out, o_scale} != {fp_out, fp_scale})) begin
            $display("MANTISSA MISMATCH: %0de%0d + %0de%0d -> %0de%0d, ref %0de%0d",
                     op0, s0, op1, s1, out, o_scale, fp_out, fp_scale);
            $display("FAILED");
            $finish();
        end
        if(!int_skip && ({out_int, o_scale_int} != {int_out, int_scale})) begin
            $display("INTEGER MISMATCH: %0de%0d + %0de%0d -> %0de%0d, ref %0de%0d",
                     op0, s0, op1, s1, out_int, o_scale_int, int_out, int_scale);
            $display("FAILED");
            $finish();
        end
    endtask


    // Issue regression vectors (mantissa mode, decoded per the shared-exponent format).
    task issue_vector(input logic [int_w-1:0] op0, input logic [scale_w-1:0] s0,
                      input logic [int_w-1:0] op1, input logic [scale_w-1:0] s1,
                      input shortreal expected);
        i_op0 = op0;
        i_op1 = op1;
        i_scale0 = s0;
        i_scale1 = s1;
        #1;
        $display("%f + %f = %f (expect %f)", fptosr(op0, s0), fptosr(op1, s1), fptosr(out, o_scale), expected);
        if(fptosr(out, o_scale) != expected) begin
            $display("FAILED");
            $finish();
        end
    endtask


    logic [int_w-1:0] r_op0, r_op1;
    logic [scale_w-1:0] r_s0, r_s1;
    integer i;

    initial begin
        // Issue regression cases.
        issue_vector(8'b01000000, 129, 8'b01000000, 127, 7.5);
        issue_vector(8'b00000000, 127, 8'b00000000, 127, 2.0);
        issue_vector(8'b00000000, 0,   8'b00000000, 0,   0.0);

        // Directed corner cases.
        test_vector(8'b01000000, 127, 8'b01000000, 127);   // Significand carry into a new binade.
        test_vector(8'b01000000, 127, 8'b11000000, 127);   // Exact cancellation.
        test_vector(8'b01000000, 127, 8'b11000000, 129);   // Mixed signs, different scales.
        test_vector(8'b01111111, 127, 8'b00000001, 127);   // Round-to-nearest-even tie.
        test_vector(8'b11111111, 200, 8'b11111111, 200);   // Negative overflow path.
        test_vector(8'b00000000, 40,  8'b01111111, 0);     // Wide scale difference.

        // Random sweep.
        for(i=0; i<20000; i++) begin
            r_op0 = $random;
            r_op1 = $random;
            r_s0 = $random & 63;
            r_s1 = $random & 63;
            test_vector(r_op0, r_s0, r_op1, r_s1);
        end

        $display("PASSED");
        $finish();
    end

endmodule
