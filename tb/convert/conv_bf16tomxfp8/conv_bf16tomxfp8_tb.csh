#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/convert/conv_bf16tomxfp_spec/conv_bf16tomxfp_spec_tb.c
xvlog --sv -svlog ../tb/convert/conv_bf16tomxfp_spec/conv_bf16tomxfp_spec_tb.sv ../src/convert/conv_bf16tomxfp_spec.sv ../src/util/rnd/fp_rnd_nan_rne.sv ../src/util/unsigned_max.sv ../src/util/clz_int.sv
xelab work.conv_bf16tomxfp_spec_tb -sv_lib dpi -R

cd ..
