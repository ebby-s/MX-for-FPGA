#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xvlog --sv -svlog ../tb/util/mul_fp/mul_fp_tb.sv ../src/util/arith/mul_fp.sv ../src/util/arith/mul_int.sv
xelab work.mul_fp_tb -sv_lib dpi -R

cd ..
