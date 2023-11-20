#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/convert/conv_bf16tomxfp6/conv_bf16tomxfp6_tb.c
xvlog --sv -svlog ../tb/convert/conv_bf16tomxfp6/conv_bf16tomxfp6_tb.sv ../src/convert/conv_bf16tomxfp6.sv ../src/util/fp_rnd_rne.sv ../src/util/unsigned_max.sv ../src/util/clz_i8.sv
xelab work.conv_bf16tomxfp6_tb -sv_lib dpi -R

cd ..
