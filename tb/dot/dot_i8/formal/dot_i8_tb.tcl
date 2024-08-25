clear -all
analyze -clear
analyze -sv tb/dot/dot_int/formal/dot_int_tb.sv src/dot/dot_int.sv src/util/vec_mul_int.sv src/util/vec_sum_int.sv src/util/mul_int.sv
elaborate -bbox_mul 16 -top dot_int_tb

clock i_clk
reset -expression !(i_rst_n)

task -set <embedded>
set_proofgrid_max_jobs 4
set_proofgrid_max_local_jobs 4
