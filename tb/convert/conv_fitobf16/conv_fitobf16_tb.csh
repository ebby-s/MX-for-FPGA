#!/bin/csh -xvf

if ( -d temp) then
    cd temp
else
    mkdir temp && cd temp
endif

xsc ../tb/convert/conv_inttobf16/conv_inttobf16_tb.c 
xvlog --sv -svlog ../tb/convert/conv_inttobf16/conv_inttobf16_tb.sv ../src/convert/conv_inttobf16.sv ../src/util/clz_int.sv
xelab work.conv_inttobf16_tb -sv_lib dpi -R

cd ..
