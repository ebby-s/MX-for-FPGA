#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xvlog --sv -svlog ../tb/dot/dot_fp/dot_fp_tb.sv ../src/dot/dot_fp.sv ../src/util/arith/vec_mul_fp.sv ../src/util/arith/vec_sum_int.sv ../src/util/arith/mul_fp.sv ../src/util/arith/mul_int.sv
xelab work.dot_fp_tb -sv_lib dpi -R

cd ..
