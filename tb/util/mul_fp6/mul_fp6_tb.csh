#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xvlog --sv -svlog ../tb/util/mul_fp6/mul_fp6_tb.sv ../src/util/arith/mul_fp6.sv ../src/util/arith/mul_i8.sv
xelab work.mul_fp6_tb -sv_lib dpi -R

cd ..
