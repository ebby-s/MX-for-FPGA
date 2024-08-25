#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xvlog --sv -svlog ../tb/dot/dot_int/dot_int_tb.sv ../src/dot/dot_int.sv ../src/util/arith/vec_mul_int.sv ../src/util/arith/vec_sum_int.sv ../src/util/arith/mul_int.sv
xelab work.dot_int_tb -sv_lib dpi -R

cd ..
