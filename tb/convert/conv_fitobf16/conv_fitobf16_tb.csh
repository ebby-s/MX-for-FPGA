#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/convert/conv_fitobf16/conv_fitobf16_tb.c 
xvlog --sv -svlog ../tb/convert/conv_fitobf16/conv_fitobf16_tb.sv ../src/convert/conv_fitobf16.sv ../src/util/clz_i8.sv
xelab work.conv_fitobf16_tb -sv_lib dpi -R

cd ..
