#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xvlog --sv -svlog ../tb/dot/dot_i8/dot_i8_tb.sv ../src/dot/dot_i8.sv ../src/util/vec_mul_i8.sv ../src/util/vec_sum_i8.sv ../src/util/mul_i8.sv
xelab work.dot_i8_tb -sv_lib dpi -R

cd ..
