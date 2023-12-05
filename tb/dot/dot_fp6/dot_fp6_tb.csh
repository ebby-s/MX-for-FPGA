#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xvlog --sv -svlog ../tb/dot/dot_fp6/dot_fp6_tb.sv ../src/dot/dot_fp6.sv ../src/util/arith/vec_mul_fp6.sv ../src/util/arith/vec_sum_i8.sv ../src/util/arith/mul_fp6.sv ../src/util/arith/mul_i8.sv
xelab work.dot_fp6_tb -sv_lib dpi -R

cd ..
