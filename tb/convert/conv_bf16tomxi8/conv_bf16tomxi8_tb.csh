#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/convert/conv_bf16tomxint/conv_bf16tomxint_tb.c
xvlog --sv -svlog ../tb/convert/conv_bf16tomxint/conv_bf16tomxint_tb.sv ../src/convert/conv_bf16tomxint.sv ../src/util/rnd/shift_rnd_rne.sv ../src/util/unsigned_max.sv
xelab work.conv_bf16tomxint_tb -sv_lib dpi -R

cd ..
