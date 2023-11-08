module unsigned_max #(
    parameter width  = 8,
    parameter length = 32
)(
    input  logic unsigned [width-1:0] i_exps [length],
    output logic unsigned [width-1:0] o_e_max
);


    logic unsigned [width-1:0] p0_e_max;

    always_comb begin
        p0_e_max = 0;
        for (int i=0; i<length; i++) begin
            if (i_exps[i] > p0_e_max)
                p0_e_max = i_exps[i];
        end
    end


    assign o_e_max = p0_e_max;

endmodule
