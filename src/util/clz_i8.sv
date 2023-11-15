module clz_i8 #(
    parameter width_i = 8,
    parameter width_o = $clog2(width_i+1)
)(
    input  logic [width_i-1:0] i_num,
    output logic [width_o-1:0] o_lz
);

    logic [width_o-1:0] num_lz;

    always_comb begin
        num_lz = 0;
        for(int i=1; i<=width_i; i++) begin
            if(i_num[width_i-i]) begin
                break;
            end else begin
                num_lz++;
            end
        end
    end

    assign o_lz = num_lz;

endmodule
