#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/convert/conv_bf16tomxfp/conv_bf16tomxfp_tb.c
xvlog --sv -svlog ../tb/convert/conv_bf16tomxfp/conv_bf16tomxfp_tb.sv ../src/convert/conv_bf16tomxfp.sv ../src/util/rnd/fp_rnd_rne.sv ../src/util/unsigned_max.sv ../src/util/clz_int.sv
xelab work.conv_bf16tomxfp_tb -sv_lib dpi -R

cd ..
