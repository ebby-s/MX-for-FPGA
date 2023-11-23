clear -all
analyze -clear
analyze -sv tb/dot/dot_i8/formal/dot_i8_tb.sv src/dot/dot_i8.sv src/util/vec_mul_i8.sv src/util/vec_sum_i8.sv src/util/mul_i8.sv
elaborate -bbox_mul 16 -top dot_i8_tb

clock i_clk
reset -expression !(i_rst_n)

task -set <embedded>
set_proofgrid_max_jobs 4
set_proofgrid_max_local_jobs 4
