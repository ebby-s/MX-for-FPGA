clear -all
analyze -clear
analyze -sv src/util/unsigned_max.sv tb/unsigned_max_tb.sv
elaborate -top unsigned_max_tb

clock i_clk
reset -expression !(i_rst_n)

task -set <embedded>
set_proofgrid_max_jobs 4
set_proofgrid_max_local_jobs 4
